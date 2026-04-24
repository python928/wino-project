from django.core.management.base import BaseCommand
from catalog.models import Category, Product
from users.models import User
from catalog.search_engine import calculate_adaptive_radius, apply_weighted_ranking
import math
from decimal import Decimal

class Command(BaseCommand):
    help = 'Verify Advanced Search Logic'

    def handle(self, *args, **options):
        self.stdout.write("--- Verifying Adaptive Radius ---")
        # Setup Test Data
        cat_bread, _ = Category.objects.get_or_create(name="Bread Test", defaults={'scarcity_level': 1})
        cat_cars, _ = Category.objects.get_or_create(name="Car Test", defaults={'scarcity_level': 10})
        
        # 1. Verify Adaptive Radius
        r_bread = calculate_adaptive_radius(cat_bread)
        r_cars = calculate_adaptive_radius(cat_cars)
        
        self.stdout.write(f"Radius Bread (Scarcity 1): {r_bread} km")
        self.stdout.write(f"Radius Car (Scarcity 10): {r_cars} km")
        
        if r_bread == 10.0 and r_cars == 55.0:
             self.stdout.write(self.style.SUCCESS('Adaptive Radius Logic Verified'))
        else:
             self.stdout.write(self.style.WARNING(f'Adaptive Radius Variance: {r_bread}, {r_cars}'))

        self.stdout.write("\n--- Verifying Weighted Ranking ---")
        
        # User location (0, 0)
        u_lat, u_lng = 0.0, 0.0
        
        # Store A: Very Close (0.001 deg ~ 100m), Expensive
        user_a, _ = User.objects.get_or_create(username='store_a', defaults={'latitude': Decimal('0.001'), 'longitude': Decimal('0.0'), 'name': 'Store A'})
        
        # Store B: Far (0.1 deg ~ 10km), Cheap
        user_b, _ = User.objects.get_or_create(username='store_b', defaults={'latitude': Decimal('0.1'), 'longitude': Decimal('0.0'), 'name': 'Store B'})
        
        # Ensure lat/lng are set (get_or_create might not update existing)
        user_a.latitude = Decimal('0.001')
        user_a.save()
        user_b.latitude = Decimal('0.1')
        user_b.save()

        prod_a, _ = Product.objects.get_or_create(name='Prod A (Close/Exp)', store=user_a, defaults={'price': 5000.0})
        prod_b, _ = Product.objects.get_or_create(name='Prod B (Far/Cheap)', store=user_b, defaults={'price': 100.0})
        
        qs = Product.objects.filter(id__in=[prod_a.id, prod_b.id])
        
        # Debug Data
        for p in qs:
            self.stdout.write(f"DEBUG: Product {p.name} Store Lat: {p.store.latitude} Lng: {p.store.longitude}")

        ranked_qs = apply_weighted_ranking(qs, u_lat, u_lng)
        
        # Debug Annotations
        debug_vals = ranked_qs.values('name', 'store__latitude', 'distance_squared', 'relevance_score')
        for val in debug_vals:
             self.stdout.write(f"DEBUG VALS: {val}")

        for p in ranked_qs:
            self.stdout.write(f"Product: {p.name}")
            self.stdout.write(f"  > Score: {getattr(p, 'relevance_score', 0):.4f}")
            self.stdout.write(f"  > DistSq: {getattr(p, 'distance_squared', 0):.6f}")
            self.stdout.write(f"  > PriceScore: {getattr(p, 'price_score', 0):.4f}")

        first = ranked_qs.first()
        self.stdout.write(self.style.SUCCESS(f"Top Result: {first.name}"))
        
        # Cleanup
        # prod_a.delete()
        # prod_b.delete()
        # cat_bread.delete()
        # cat_cars.delete()
