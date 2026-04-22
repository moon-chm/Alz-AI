from typing import List, Dict

def is_point_in_polygon(lat: float, lng: float, polygon: List[Dict[str, float]]) -> bool:
    """
    Ray Casting algorithm to check if a point is inside a polygon.
    polygon: List of points like [{'lat': 12.3, 'lng': 45.6}, ...]
    """
    if not polygon or len(polygon) < 3:
        return True  # If no geofence defined, patient is "safe"

    is_inside = False
    n = len(polygon)
    p1 = polygon[0]
    
    for i in range(1, n + 1):
        p2 = polygon[i % n]
        if lng > min(p1['lng'], p2['lng']):
            if lng <= max(p1['lng'], p2['lng']):
                if lat <= max(p1['lat'], p2['lat']):
                    if p1['lng'] != p2['lng']:
                        x_inters = (lng - p1['lng']) * (p2['lat'] - p1['lat']) / (p2['lng'] - p1['lng']) + p1['lat']
                        if p1['lat'] == p2['lat'] or lat <= x_inters:
                            is_inside = not is_inside
        p1 = p2
        
    return is_inside
