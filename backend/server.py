from fastapi import FastAPI, APIRouter
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from pydantic import BaseModel, Field, ConfigDict
from typing import List
import uuid
from datetime import datetime, timezone
import requests


ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

# Create the main app without a prefix
app = FastAPI()

# Create a router with the /api prefix
api_router = APIRouter(prefix="/api")


# Define Models
class StatusCheck(BaseModel):
    model_config = ConfigDict(extra="ignore")  # Ignore MongoDB's _id field
    
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    client_name: str
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class StatusCheckCreate(BaseModel):
    client_name: str

# Add your routes to the router instead of directly to app
@api_router.get("/")
async def root():
    return {"message": "Hello World"}

@api_router.post("/status", response_model=StatusCheck)
async def create_status_check(input: StatusCheckCreate):
    status_dict = input.model_dump()
    status_obj = StatusCheck(**status_dict)
    
    # Convert to dict and serialize datetime to ISO string for MongoDB
    doc = status_obj.model_dump()
    doc['timestamp'] = doc['timestamp'].isoformat()
    
    _ = await db.status_checks.insert_one(doc)
    return status_obj

@api_router.get("/status", response_model=List[StatusCheck])
async def get_status_checks():
    # Exclude MongoDB's _id field from the query results
    status_checks = await db.status_checks.find({}, {"_id": 0}).to_list(1000)
    
    # Convert ISO string timestamps back to datetime objects
    for check in status_checks:
        if isinstance(check['timestamp'], str):
            check['timestamp'] = datetime.fromisoformat(check['timestamp'])
    
    return status_checks

# NOTE: router will be included after all routes are defined (see bottom)
app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


# --- Places proxy endpoints -----------------------------------------------
PLACES_API_KEY = os.environ.get('PLACES_API_KEY')


@api_router.get('/places/autocomplete')
def places_autocomplete(input: str, lat: float = None, lng: float = None, radius: int = 50000):
    """Proxy to Google Places Autocomplete Web Service.
    Query parameters:
      - input: search string (required)
      - lat, lng: optional location to bias results
      - radius: optional radius in meters (default 50000)
    Returns the raw JSON response from Google.
    """
    if not PLACES_API_KEY:
        return {"error": "PLACES_API_KEY not configured on server"}

    url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
    params = {
        'input': input,
        'key': PLACES_API_KEY,
        'language': 'pt-BR'
    }
    if lat is not None and lng is not None:
        params['location'] = f"{lat},{lng}"
        params['radius'] = str(radius)

    try:
        resp = requests.get(url, params=params, timeout=5)
        return resp.json()
    except Exception as e:
        logger.exception('Places autocomplete proxy error')
        return {"error": str(e)}


@api_router.get('/places/details')
def places_details(place_id: str):
    """Proxy to Google Places Details Web Service.
    Query parameters:
      - place_id: the place_id returned by autocomplete (required)
    Returns the raw JSON response from Google.
    """
    if not PLACES_API_KEY:
        return {"error": "PLACES_API_KEY not configured on server"}

    url = 'https://maps.googleapis.com/maps/api/place/details/json'
    params = {
        'place_id': place_id,
        'fields': 'name,formatted_address,geometry',
        'key': PLACES_API_KEY,
        'language': 'pt-BR'
    }

    try:
        resp = requests.get(url, params=params, timeout=5)
        return resp.json()
    except Exception as e:
        logger.exception('Places details proxy error')
        return {"error": str(e)}


@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()


# Include the router in the main app (must happen after all @api_router routes are declared)
app.include_router(api_router)