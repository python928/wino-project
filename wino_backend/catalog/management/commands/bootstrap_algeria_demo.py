import random
import urllib.error
import urllib.parse
import urllib.request
from datetime import date, timedelta
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand
from django.utils import timezone

from analytics.models import InteractionLog, UserInterestProfile
from analytics.scoring import update_all_profiles
from catalog.models import (
    Category,
    Favorite,
    Pack,
    PackImage,
    PackProduct,
    Product,
    ProductImage,
    ProductReport,
    Promotion,
    Review,
)
from feedback.models import Feedback
from subscriptions.models import (
    MerchantSubscription,
    SubscriptionPaymentConfig,
    SubscriptionPaymentProof,
    SubscriptionPaymentRequest,
    SubscriptionPlan,
)
from subscriptions.services import bootstrap_default_subscription_plans
from users.models import Follower, StoreReport, SystemSettings, TrustSettings
from users.trust_scoring import (
    evaluate_store_verification,
    score_product_report,
    score_review_credibility,
    score_store_report,
)
from wallet.models import CoinPackPlan, CoinPurchase, CoinPurchaseProof
from wallet.services import approve_coin_purchase, grant_coins

User = get_user_model()


CATEGORY_BLUEPRINTS = [
    {
        "key": "cookware",
        "name_en": "Cookware & Kitchen",
        "name_fr": "Cuisine & Ustensiles",
        "name_ar": "أواني ومطبخ",
        "icon_code_point": "e56c",
        "scarcity_level": 2,
    },
    {
        "key": "fashion",
        "name_en": "Fashion & Shoes",
        "name_fr": "Mode & Chaussures",
        "name_ar": "ألبسة وأحذية",
        "icon_code_point": "eb44",
        "scarcity_level": 2,
    },
    {
        "key": "beauty",
        "name_en": "Beauty & Perfume",
        "name_fr": "Beaute & Parfum",
        "name_ar": "جمال وعطور",
        "icon_code_point": "e3be",
        "scarcity_level": 2,
    },
    {
        "key": "accessories",
        "name_en": "Accessories & Gifts",
        "name_fr": "Accessoires & Cadeaux",
        "name_ar": "اكسسوارات وهدايا",
        "icon_code_point": "e87d",
        "scarcity_level": 3,
    },
    {
        "key": "furniture",
        "name_en": "Furniture & Tables",
        "name_fr": "Meubles & Maison",
        "name_ar": "أثاث وطاولات",
        "icon_code_point": "f1c5",
        "scarcity_level": 5,
    },
    {
        "key": "livestock",
        "name_en": "Livestock & Sheep",
        "name_fr": "Betail & Moutons",
        "name_ar": "ماشية وخرفان",
        "icon_code_point": "e59a",
        "scarcity_level": 8,
    },
    {
        "key": "meat",
        "name_en": "Meat & Butchery",
        "name_fr": "Boucherie & Viande",
        "name_ar": "لحوم وملحمة",
        "icon_code_point": "f8d6",
        "scarcity_level": 3,
    },
    {
        "key": "cars",
        "name_en": "Cars & Vehicles",
        "name_fr": "Voitures & Vehicules",
        "name_ar": "سيارات ومركبات",
        "icon_code_point": "e531",
        "scarcity_level": 9,
    },
    {
        "key": "school",
        "name_en": "School Supplies",
        "name_fr": "Fournitures Scolaires",
        "name_ar": "أدوات مدرسية",
        "icon_code_point": "e80c",
        "scarcity_level": 2,
    },
    {
        "key": "phones",
        "name_en": "Phones & Accessories",
        "name_fr": "Telephones & Accessoires",
        "name_ar": "هواتف وملحقات",
        "icon_code_point": "e324",
        "scarcity_level": 3,
    },
    {
        "key": "grocery",
        "name_en": "Groceries & Local Food",
        "name_fr": "Epicerie & Produits Locaux",
        "name_ar": "مواد غذائية محلية",
        "icon_code_point": "e56c",
        "scarcity_level": 1,
    },
    {
        "key": "tools_garden",
        "name_en": "Tools, DIY & Garden",
        "name_fr": "Outils, Bricolage & Jardin",
        "name_ar": "أدوات وأشغال وحديقة",
        "icon_code_point": "e869",
        "scarcity_level": 6,
    },
    {
        "key": "services",
        "name_en": "Services & Custom Orders",
        "name_fr": "Services & Commandes",
        "name_ar": "خدمات وطلبات",
        "icon_code_point": "e8b8",
        "scarcity_level": 6,
    },
]


STORE_BLUEPRINTS = [
    {
        "username": "dar.ouani.hydra",
        "name": "دار أواني حيدرة",
        "email": "dar.ouani@demo.toprice.local",
        "password": "Demo@12345",
        "phone": "0550123041",
        "gender": "female",
        "birthday": date(1993, 5, 12),
        "category_key": "cookware",
        "address": "Hydra, Alger",
        "commune": "Hydra",
        "wilaya": "Alger",
        "latitude": Decimal("36.739700"),
        "longitude": Decimal("3.040000"),
        "store_type": "physical",
        "store_description": "متجر مختص في أواني المطبخ، صواني التقديم، أطقم الشاي، ولوازم الطبخ اليومية.",
        "instagram": "dar.ouani.hydra",
        "facebook": "darouanihydra",
        "whatsapp": "0550123041",
        "cover_tags": ["cookware", "kitchen", "shop"],
        "product_image_queries": [
            ["cookware", "pots"],
            ["kitchen", "pan"],
            ["tea set", "kitchen"],
            ["tajine", "pottery"],
        ],
        "profile_index": 12,
        "supports_packs": True,
        "delivery_wilayas": ["Alger", "Blida", "Boumerdes", "Tipaza"],
    },
    {
        "username": "atlas.meuble.setif",
        "name": "أطلس للأثاث سطيف",
        "email": "atlas.meuble@demo.toprice.local",
        "password": "Demo@12345",
        "phone": "0661382054",
        "gender": "male",
        "birthday": date(1989, 8, 4),
        "category_key": "furniture",
        "address": "Setif Centre, Setif",
        "commune": "Setif",
        "wilaya": "Setif",
        "latitude": Decimal("36.191100"),
        "longitude": Decimal("5.413700"),
        "store_type": "physical",
        "store_description": "أثاث منزلي يشمل الكراسي والطاولات والخزائن وتجهيزات غرف الجلوس.",
        "instagram": "atlas.meuble.setif",
        "facebook": "atlasmeublesetif",
        "whatsapp": "0661382054",
        "cover_tags": ["furniture", "chairs", "showroom"],
        "product_image_queries": [
            ["chair", "furniture"],
            ["table", "dining"],
            ["sofa", "living room"],
            ["wardrobe", "furniture"],
        ],
        "profile_index": 22,
        "supports_packs": False,
        "delivery_wilayas": ["Setif", "Bordj Bou Arreridj", "Mila", "Bejaia"],
    },
    {
        "username": "soug.elmawashi.khroub",
        "name": "سوق المواشي الخروب",
        "email": "soug.mawashi@demo.toprice.local",
        "password": "Demo@12345",
        "phone": "0770439182",
        "gender": "male",
        "birthday": date(1987, 11, 24),
        "category_key": "livestock",
        "address": "El Khroub, Constantine",
        "commune": "El Khroub",
        "wilaya": "Constantine",
        "latitude": Decimal("36.264100"),
        "longitude": Decimal("6.693700"),
        "store_type": "physical",
        "store_description": "بيع الخرفان والأغنام والمواشي الموسمية للعائلات والقصابين.",
        "instagram": "soug.elmawashi.khroub",
        "facebook": "sougelmawashikhroub",
        "whatsapp": "0770439182",
        "cover_tags": ["sheep", "farm", "livestock"],
        "product_image_queries": [
            ["sheep", "livestock"],
            ["ram", "farm"],
            ["goat", "market"],
        ],
        "profile_index": 31,
        "supports_packs": False,
        "delivery_wilayas": ["Constantine", "Mila", "Oum El Bouaghi", "Guelma"],
    },
    {
        "username": "boucherie.elbahia.oran",
        "name": "ملحمة الباهية وهران",
        "email": "boucherie.elbahia@demo.toprice.local",
        "password": "Demo@12345",
        "phone": "0557334206",
        "gender": "male",
        "birthday": date(1990, 3, 17),
        "category_key": "meat",
        "address": "Oran Centre, Oran",
        "commune": "Oran",
        "wilaya": "Oran",
        "latitude": Decimal("35.697100"),
        "longitude": Decimal("-0.630800"),
        "store_type": "physical",
        "store_description": "لحوم طازجة تشمل لحم الغنم وقطع البقر واللحم المفروم وصواني جاهزة.",
        "instagram": "boucherie.elbahia.oran",
        "facebook": "boucherieelbahiaoran",
        "whatsapp": "0557334206",
        "cover_tags": ["butcher", "meat", "shop"],
        "product_image_queries": [
            ["butcher", "meat"],
            ["lamb meat", "butcher"],
            ["beef cut", "butcher"],
        ],
        "profile_index": 41,
        "supports_packs": False,
        "delivery_wilayas": ["Oran", "Mostaganem", "Mascara", "Ain Temouchent"],
    },
    {
        "username": "sarah.mode.annaba",
        "name": "سارة مود عنابة",
        "email": "sarah.mode@demo.toprice.local",
        "password": "Demo@12345",
        "phone": "0664221490",
        "gender": "female",
        "birthday": date(1995, 1, 9),
        "category_key": "fashion",
        "address": "Annaba Centre, Annaba",
        "commune": "Annaba",
        "wilaya": "Annaba",
        "latitude": Decimal("36.900000"),
        "longitude": Decimal("7.766700"),
        "store_type": "online",
        "store_description": "ملابس نسائية ورجالية تشمل الجلابيب والفساتين والبدلات الرياضية والقطع اليومية.",
        "instagram": "sarah.mode.annaba",
        "facebook": "sarahmodeannaba",
        "whatsapp": "0664221490",
        "cover_tags": ["clothes", "boutique", "fashion"],
        "product_image_queries": [
            ["clothes", "boutique"],
            ["dress", "fashion"],
            ["jilbab", "modest fashion"],
            ["shirt", "clothing"],
        ],
        "profile_index": 63,
        "supports_packs": True,
        "delivery_wilayas": ["Annaba", "El Tarf", "Skikda", "Guelma"],
    },
    {
        "username": "aya.accessoires.blida",
        "name": "آية للإكسسوارات البليدة",
        "email": "aya.accessoires@demo.toprice.local",
        "password": "Demo@12345",
        "phone": "0771275088",
        "gender": "female",
        "birthday": date(1996, 9, 28),
        "category_key": "accessories",
        "address": "Blida Centre, Blida",
        "commune": "Blida",
        "wilaya": "Blida",
        "latitude": Decimal("36.470000"),
        "longitude": Decimal("2.828900"),
        "store_type": "physical",
        "store_description": "حقائب ومحافظ وساعات وأوشحة وإكسسوارات هدايا مطلوبة يوميًا.",
        "instagram": "aya.accessoires.blida",
        "facebook": "ayaaccessoiresblida",
        "whatsapp": "0771275088",
        "cover_tags": ["accessories", "bags", "store"],
        "product_image_queries": [
            ["handbag", "accessories"],
            ["watch", "fashion"],
            ["sunglasses", "accessories"],
            ["wallet", "gift"],
        ],
        "profile_index": 57,
        "supports_packs": True,
        "delivery_wilayas": ["Blida", "Alger", "Medea", "Tipaza"],
    },
    {
        "username": "fares.auto.sba",
        "name": "فارس أوتو سيدي بلعباس",
        "email": "fares.auto@demo.toprice.local",
        "password": "Demo@12345",
        "phone": "0554018897",
        "gender": "male",
        "birthday": date(1988, 7, 21),
        "category_key": "cars",
        "address": "Sidi Bel Abbes, Sidi Bel Abbes",
        "commune": "Sidi Bel Abbes",
        "wilaya": "Sidi Bel Abbes",
        "latitude": Decimal("35.189600"),
        "longitude": Decimal("-0.631000"),
        "store_type": "physical",
        "store_description": "سيارات مستعملة للمدينة والعائلة مع بعض لوازم وإكسسوارات السيارات.",
        "instagram": "fares.auto.sba",
        "facebook": "faresautosba",
        "whatsapp": "0554018897",
        "cover_tags": ["car", "showroom", "vehicle"],
        "product_image_queries": [
            ["car", "sedan"],
            ["used car", "hatchback"],
            ["car", "showroom"],
        ],
        "profile_index": 45,
        "supports_packs": False,
        "delivery_wilayas": ["Sidi Bel Abbes", "Oran", "Mascara", "Tlemcen"],
    },
    {
        "username": "maktabati.tlemcen",
        "name": "مكتبتي تلمسان",
        "email": "maktabati.tlemcen@demo.toprice.local",
        "password": "Demo@12345",
        "phone": "0668021733",
        "gender": "female",
        "birthday": date(1991, 12, 5),
        "category_key": "school",
        "address": "Tlemcen Centre, Tlemcen",
        "commune": "Tlemcen",
        "wilaya": "Tlemcen",
        "latitude": Decimal("34.878300"),
        "longitude": Decimal("-1.315000"),
        "store_type": "online",
        "store_description": "لوازم مدرسية تشمل الدفاتر والأقلام والحقائب وأدوات الهندسة ومستلزمات الدراسة.",
        "instagram": "maktabati.tlemcen",
        "facebook": "maktabatitlemcen",
        "whatsapp": "0668021733",
        "cover_tags": ["stationery", "school", "shop"],
        "product_image_queries": [
            ["notebook", "school"],
            ["pen", "stationery"],
            ["school bag", "supplies"],
            ["pencil case", "stationery"],
        ],
        "profile_index": 51,
        "supports_packs": True,
        "delivery_wilayas": ["Tlemcen", "Oran", "Ain Temouchent", "Sidi Bel Abbes"],
    },
    {
        "username": "yacine.mobile.babez",
        "name": "ياسين موبايل باب الزوار",
        "email": "yacine.mobile@demo.toprice.local",
        "password": "Demo@12345",
        "phone": "0777801559",
        "gender": "male",
        "birthday": date(1992, 4, 15),
        "category_key": "phones",
        "address": "Bab Ezzouar, Alger",
        "commune": "Bab Ezzouar",
        "wilaya": "Alger",
        "latitude": Decimal("36.721900"),
        "longitude": Decimal("3.183800"),
        "store_type": "physical",
        "store_description": "هواتف ذكية وإكسسوارات الموبايل مثل الشواحن والسماعات ولوازم الاستخدام اليومي.",
        "instagram": "yacine.mobile.babez",
        "facebook": "yacinemobilebabez",
        "whatsapp": "0777801559",
        "cover_tags": ["phone", "electronics", "shop"],
        "product_image_queries": [
            ["smartphone", "electronics"],
            ["phone accessories", "shop"],
            ["earbuds", "mobile"],
            ["charger", "phone"],
        ],
        "profile_index": 61,
        "supports_packs": True,
        "delivery_wilayas": ["Alger", "Blida", "Boumerdes", "Tipaza"],
    },
    {
        "username": "lina.beaute.bejaia",
        "name": "لينا بيوتي بجاية",
        "email": "lina.beaute@demo.toprice.local",
        "password": "Demo@12345",
        "phone": "0552843775",
        "gender": "female",
        "birthday": date(1994, 6, 11),
        "category_key": "beauty",
        "address": "Bejaia Centre, Bejaia",
        "commune": "Bejaia",
        "wilaya": "Bejaia",
        "latitude": Decimal("36.752500"),
        "longitude": Decimal("5.084000"),
        "store_type": "online",
        "store_description": "عطور ومنتجات عناية بالبشرة ومستحضرات تجميل مناسبة للاستعمال اليومي والهدايا.",
        "instagram": "lina.beaute.bejaia",
        "facebook": "linabeautebejaia",
        "whatsapp": "0552843775",
        "cover_tags": ["beauty", "perfume", "boutique"],
        "product_image_queries": [
            ["perfume", "beauty"],
            ["skincare", "cosmetics"],
            ["makeup", "beauty"],
            ["cream", "skincare"],
        ],
        "profile_index": 71,
        "supports_packs": True,
        "delivery_wilayas": ["Bejaia", "Setif", "Tizi Ouzou", "Jijel"],
    },
]


PRODUCT_TEMPLATES = {
    "cookware": [
        {"name": "Couscoussier Aluminium 10L", "price": "7800", "description": "Large couscoussier suited for family meals and weekends."},
        {"name": "Set Marmites Inox 5 Pieces", "price": "12400", "description": "Stainless steel pot set for daily cooking."},
        {"name": "Poele Antiadhesive 30cm", "price": "2900", "description": "Practical non-stick pan for eggs, meats, and vegetables."},
        {"name": "Autocuiseur 8L", "price": "9500", "description": "Pressure cooker commonly used for chorba and lunch prep."},
        {"name": "Service a The 12 Pieces", "price": "6400", "description": "Traditional tea set for guests and family visits."},
        {"name": "Tajine Terre Cuite", "price": "2200", "description": "Clay tajine for oven or slow cooking."},
        {"name": "Plateau Inox Rectangulaire", "price": "1800", "description": "Serving tray for tea, coffee, and pastries."},
        {"name": "Set Assiettes 18 Pieces", "price": "6900", "description": "Dinner plate set for everyday family service."},
        {"name": "Bouilloire Inox 2L", "price": "2500", "description": "Stovetop kettle for tea and herbs."},
        {"name": "Boites a Epices 6 Pieces", "price": "1600", "description": "Compact spice jars for kitchen organization."},
    ],
    "furniture": [
        {"name": "Chaise Salle a Manger Bois", "price": "5200", "description": "Wooden dining chair with durable seat."},
        {"name": "Table Basse Salon", "price": "11800", "description": "Coffee table for living rooms and reception spaces."},
        {"name": "Table a Manger 6 Places", "price": "39800", "description": "Dining table sized for family gatherings."},
        {"name": "Canape Trois Places", "price": "76500", "description": "Comfortable sofa in neutral fabric."},
        {"name": "Armoire 2 Portes", "price": "44800", "description": "Bedroom wardrobe with hanging and shelf space."},
        {"name": "Bureau Etudiant 120cm", "price": "15200", "description": "Simple study desk for home use."},
        {"name": "Chaise Bureau Rembourree", "price": "9800", "description": "Padded office chair for work or school."},
        {"name": "Table TV Moderne", "price": "18400", "description": "TV cabinet with storage shelves."},
        {"name": "Commode Chambre 4 Tiroirs", "price": "21400", "description": "Compact chest for clothing and linens."},
        {"name": "Etagere Bibliotheque 5 Niveaux", "price": "13600", "description": "Shelf unit for books and decor."},
    ],
    "livestock": [
        {"name": "Kebch 42kg El Khroub", "price": "87000", "description": "Healthy ram ready for household purchase."},
        {"name": "Mouton Sardi 38kg", "price": "79000", "description": "Well-fed sheep suitable for family needs."},
        {"name": "Naaja Elevage 2 Ans", "price": "59000", "description": "Breeding ewe from local stock."},
        {"name": "Kebch Blanc 45kg", "price": "92000", "description": "Strong ram with visible good condition."},
        {"name": "Mouton Local 36kg", "price": "74000", "description": "Local sheep with veterinary follow-up."},
        {"name": "Agnel 28kg", "price": "62000", "description": "Young lamb for smaller-family purchase."},
        {"name": "Chevre Laitiere", "price": "46000", "description": "Dairy goat from regular farm care."},
        {"name": "Kebch Noir 41kg", "price": "84500", "description": "Ram with balanced weight and good appearance."},
        {"name": "Duo Moutons 2x34kg", "price": "138000", "description": "Two sheep sold together for larger households."},
        {"name": "Kebch Saison Printemps", "price": "90500", "description": "Seasonal livestock listing with current weight noted."},
    ],
    "meat": [
        {"name": "Gigot Agneau 2kg", "price": "5600", "description": "Fresh lamb leg cut prepared the same day."},
        {"name": "Cotelettes Veau 1kg", "price": "3200", "description": "Veal chops for grilling or oven use."},
        {"name": "Viande Hachee Boeuf 1kg", "price": "2300", "description": "Lean beef mince for sauce or burgers."},
        {"name": "Foie Agneau 500g", "price": "1450", "description": "Fresh lamb liver cut and packed cleanly."},
        {"name": "Merguez Maison 1kg", "price": "2100", "description": "House-made merguez with balanced spices."},
        {"name": "Escalope Poulet 1kg", "price": "1450", "description": "Chicken fillet sliced for pan cooking."},
        {"name": "Cubes Viande Tajine 1kg", "price": "2550", "description": "Boneless meat cubes for tajines and sauces."},
        {"name": "Queue de Boeuf 1kg", "price": "1750", "description": "Cut suited for soup and long cooking."},
        {"name": "Cotelette Agneau 1kg", "price": "3350", "description": "Lamb chops selected for grilling."},
        {"name": "Plateau Mixte Grillade 2kg", "price": "6100", "description": "Mixed tray for barbecue and family meals."},
    ],
    "fashion": [
        {"name": "Jilbab Crepe Premium", "price": "5900", "description": "Light jilbab for daily use and visits."},
        {"name": "Robe Longue Soiree Simple", "price": "7600", "description": "Long dress for events and modest styling."},
        {"name": "Jeans Homme Straight Fit", "price": "4500", "description": "Straight-cut jeans for everyday wear."},
        {"name": "Chemise Homme Bureau", "price": "2900", "description": "Light formal shirt for work and occasions."},
        {"name": "Ensemble Sport Femme", "price": "4800", "description": "Comfortable tracksuit for outings and travel."},
        {"name": "Abaya Noire Legere", "price": "5200", "description": "Simple abaya with fluid cut."},
        {"name": "Baskets Ville Mixte", "price": "6900", "description": "Daily sneakers for city use."},
        {"name": "Pyjama Enfant 2 Pieces", "price": "2200", "description": "Soft pajama for children."},
        {"name": "Hijab Jersey Uni", "price": "1100", "description": "Stretch hijab in everyday colors."},
        {"name": "Veste Mi-Saison Homme", "price": "6300", "description": "Seasonal jacket for spring and autumn."},
    ],
    "accessories": [
        {"name": "Sac a Main Noir Moyen", "price": "4300", "description": "Medium handbag for daily and occasion outfits."},
        {"name": "Portefeuille Femme Simili Cuir", "price": "1800", "description": "Compact wallet with card and cash pockets."},
        {"name": "Montre Quartz Classique", "price": "3900", "description": "Simple watch for everyday outfits."},
        {"name": "Lunettes Soleil UV400", "price": "1700", "description": "Classic sunglasses for sunny days."},
        {"name": "Ceinture Homme Cuir", "price": "1600", "description": "Belt suited for jeans and formal trousers."},
        {"name": "Coffret Collier + Boucles", "price": "2400", "description": "Gift set for birthdays and visits."},
        {"name": "Echarpe Legere Femme", "price": "1200", "description": "Light scarf for daily use."},
        {"name": "Sac a Dos Ville Compact", "price": "3500", "description": "Urban backpack for casual outings."},
        {"name": "Parfum Poche 35ml", "price": "1400", "description": "Portable scent bottle for handbags."},
        {"name": "Porte-Cles Metal Cadeau", "price": "700", "description": "Small gift accessory for daily use."},
    ],
    "cars": [
        {"name": "Renault Clio 4 2017", "price": "2480000", "description": "City car, petrol, clean body and regular papers."},
        {"name": "Peugeot 208 2018", "price": "2890000", "description": "Popular family hatchback in good visual condition."},
        {"name": "Hyundai Accent RB 2016", "price": "2140000", "description": "Sedan for daily commuting and family use."},
        {"name": "Volkswagen Golf 7 2015", "price": "3380000", "description": "Well-known compact car with practical interior."},
        {"name": "Dacia Logan 2019", "price": "1980000", "description": "Economic sedan with strong resale demand."},
        {"name": "Fiat Doblo 2014", "price": "1720000", "description": "Utility vehicle suitable for small business transport."},
        {"name": "Seat Ibiza 2017", "price": "2260000", "description": "Compact hatchback with balanced size and price."},
        {"name": "Toyota Yaris 2018", "price": "3070000", "description": "Reliable city car for regular use."},
        {"name": "Tapis Sol Universel Auto", "price": "4200", "description": "Practical interior mats for quick add-on sales."},
        {"name": "Camera Recul Universelle", "price": "6800", "description": "Reverse camera for parking support."},
    ],
    "school": [
        {"name": "Cahier 96 Pages", "price": "120", "description": "Standard notebook for primary and middle school."},
        {"name": "Stylo Bleu 10 Pieces", "price": "250", "description": "Ballpoint pen pack for class use."},
        {"name": "Sac a Dos Scolaire", "price": "3200", "description": "School backpack with two main compartments."},
        {"name": "Trousse Simple Zippee", "price": "650", "description": "Pencil case for daily school items."},
        {"name": "Boite Geometrie Complete", "price": "950", "description": "Compass, ruler, and geometry tools set."},
        {"name": "Crayons Couleur 12", "price": "480", "description": "Color pencils for drawing classes."},
        {"name": "Ramette Papier A4", "price": "720", "description": "A4 paper ream for home and study printing."},
        {"name": "Calculatrice College", "price": "1450", "description": "Simple calculator for school exercises."},
        {"name": "Marqueurs Tableau Blanc 4", "price": "520", "description": "Whiteboard marker pack for teachers and tutors."},
        {"name": "Agenda Scolaire 2026", "price": "390", "description": "School diary for schedules and homework."},
    ],
    "phones": [
        {"name": "Samsung Galaxy A16 128GB", "price": "34900", "description": "Popular mid-range phone with sealed box."},
        {"name": "Redmi Note 14 256GB", "price": "42900", "description": "Large battery and practical day-to-day performance."},
        {"name": "iPhone 13 128GB", "price": "118000", "description": "Clean used iPhone with healthy battery."},
        {"name": "Infinix Hot 50 256GB", "price": "31800", "description": "Affordable phone with good storage."},
        {"name": "Ecouteurs Bluetooth Pop", "price": "3900", "description": "Wireless earbuds for calls and music."},
        {"name": "Chargeur Rapide 25W", "price": "2500", "description": "Fast charger for modern Android devices."},
        {"name": "Power Bank 20000mAh", "price": "6200", "description": "Portable battery for travel and workdays."},
        {"name": "Montre Connectee Simple", "price": "7600", "description": "Basic smartwatch with notifications and steps."},
        {"name": "Cable USB-C Tresse 2m", "price": "1100", "description": "Long braided cable for home use."},
        {"name": "Support Voiture Telephone", "price": "950", "description": "Dashboard holder for navigation."},
    ],
    "beauty": [
        {"name": "Parfum Femme 50ml", "price": "4200", "description": "Gift-friendly perfume bottle for daily wear."},
        {"name": "Creme Hydratante Visage", "price": "1600", "description": "Face cream for simple skincare routine."},
        {"name": "Serum Niacinamide 30ml", "price": "2600", "description": "Serum for balanced skin texture."},
        {"name": "Shampoing Cheveux Secs", "price": "1450", "description": "Haircare shampoo for dry and treated hair."},
        {"name": "Mascara Noir Volume", "price": "1800", "description": "Daily mascara for natural makeup looks."},
        {"name": "Ecran Solaire SPF50", "price": "3100", "description": "High-protection sunscreen for summer use."},
        {"name": "Brume Parfumee 250ml", "price": "1350", "description": "Body mist for handbags and quick refresh."},
        {"name": "Palette Nude 12 Couleurs", "price": "2300", "description": "Neutral makeup palette for simple looks."},
        {"name": "Savon Exfoliant Doux", "price": "700", "description": "Soft exfoliating soap for shower routine."},
        {"name": "Coffret Cadeau Soin", "price": "3900", "description": "Gift beauty set with cream and body mist."},
    ],
}


PROMOTION_COPY = [
    "Flash deal for the weekend with limited stock.",
    "Popular item with a short discount window.",
    "Promo created for the demo launch catalogue.",
]

REVIEW_COMMENTS = [
    "Fast response and careful packaging.",
    "Product matched the photos and arrived on time.",
    "Good quality for the listed price.",
    "Seller communication was clear and helpful.",
    "Satisfied overall and would order again.",
    "Delivery was a bit slow, but the item was okay.",
    "The store was professional during follow-up.",
    "Nice finishing and exactly what I needed.",
]

STORE_REPORT_TEXTS = {
    "spam": "Repeated promotional messages and duplicate store shares in comments.",
    "fake": "The storefront uses generic photos and unclear product sourcing.",
    "fraud": "Customer claimed the final requested amount differed from the post.",
    "offensive": "Public replies included inappropriate wording in one conversation.",
    "other": "The listing quality is inconsistent and needs moderation review.",
}

PRODUCT_REPORT_TEXTS = {
    "spam": "This product appears reposted multiple times with small title changes.",
    "fake": "Image quality suggests stock photos instead of the actual item.",
    "fraud": "The seller allegedly changed the agreed condition after contact.",
    "offensive": "Product description contains wording unsuitable for the catalogue.",
    "other": "Information on delivery or availability is incomplete.",
}

FEEDBACK_ITEMS = [
    ("problem", "Search results in nearby mode should show clearer delivery areas.", "open"),
    ("suggestion", "Add a badge explaining why a verified store was approved.", "resolved"),
    ("problem", "The wallet screen needs clearer coin usage history for merchants.", "in_review"),
    ("suggestion", "Allow merchants to duplicate an old post when stock returns.", "open"),
    ("problem", "Some users still expect exact commune filters inside the search tab.", "in_review"),
    ("suggestion", "Expose report resolution notes to admins in a single moderation card.", "resolved"),
]

COIN_PACK_BLUEPRINTS = [
    {"pack_id": "demo_start_80", "coins_amount": 80, "price_amount": "800", "original_price_amount": "1000", "title": "Launch 80", "promo_badge": "Popular", "is_promoted": True, "sort_order": 1},
    {"pack_id": "demo_plus_180", "coins_amount": 180, "price_amount": "1600", "original_price_amount": "2100", "title": "Growth 180", "promo_badge": "Save 24%", "is_promoted": True, "sort_order": 2},
    {"pack_id": "demo_pro_360", "coins_amount": 360, "price_amount": "2900", "original_price_amount": "3800", "title": "Merchant Pro", "promo_badge": "Best value", "is_promoted": True, "sort_order": 3},
    {"pack_id": "demo_boost_700", "coins_amount": 700, "price_amount": "5200", "original_price_amount": "7000", "title": "Ads Boost 700", "promo_badge": "Top seller", "is_promoted": False, "sort_order": 4},
]


class Command(BaseCommand):
    help = (
        "Bootstrap a complete Algeria-focused demo dataset with categories, 10 realistic stores, "
        "100 products, media downloads, subscriptions, reports, reviews, and moderation settings."
    )

    def add_arguments(self, parser):
        parser.add_argument("--seed", type=int, default=20260401)
        parser.add_argument("--skip-images", action="store_true", help="Create all demo entities without downloading remote images.")
        parser.add_argument("--clear-existing", action="store_true", help="Delete previously seeded demo users before reseeding.")
        parser.add_argument("--download-timeout", type=int, default=4)

    def handle(self, *args, **options):
        self.rng = random.Random(options["seed"])
        self.skip_images = bool(options["skip_images"])
        self.download_timeout = int(options["download_timeout"] or 25)
        self.download_cache = {}
        self.image_fallback_cache = {}

        if options["clear_existing"]:
            self._clear_existing_demo_data()

        admin_user = self._ensure_admin_user()
        categories = self._seed_categories()
        stores = self._seed_stores(categories)
        products = self._seed_products(stores, categories)
        promotions = self._seed_promotions(stores, products)
        packs = self._seed_packs(stores, products)
        favorites = self._seed_favorites(stores, products)
        followers = self._seed_followers(stores)
        interactions = self._seed_interactions(stores, products, categories)
        reviews = self._seed_reviews(stores, products)
        store_reports, product_reports = self._seed_reports(stores, products)
        feedback_items = self._seed_feedback(stores)
        subscriptions, payment_requests = self._seed_subscriptions(admin_user, stores)
        purchases = self._seed_wallet(admin_user, stores)
        verified = self._seed_settings_and_verifications(admin_user, stores)
        updated_profiles = update_all_profiles()

        self.stdout.write(self.style.SUCCESS("Algeria demo bootstrap completed."))
        self.stdout.write(self.style.SUCCESS(f"Categories: {len(categories)}"))
        self.stdout.write(self.style.SUCCESS(f"Stores: {len(stores)}"))
        self.stdout.write(self.style.SUCCESS(f"Products: {len(products)}"))
        self.stdout.write(self.style.SUCCESS(f"Promotions: {promotions}"))
        self.stdout.write(self.style.SUCCESS(f"Packs: {packs}"))
        self.stdout.write(self.style.SUCCESS(f"Favorites: {favorites}"))
        self.stdout.write(self.style.SUCCESS(f"Followers: {followers}"))
        self.stdout.write(self.style.SUCCESS(f"Interaction logs: {interactions}"))
        self.stdout.write(self.style.SUCCESS(f"Reviews: {reviews}"))
        self.stdout.write(self.style.SUCCESS(f"Store reports: {store_reports}"))
        self.stdout.write(self.style.SUCCESS(f"Product reports: {product_reports}"))
        self.stdout.write(self.style.SUCCESS(f"Feedback items: {feedback_items}"))
        self.stdout.write(self.style.SUCCESS(f"Subscriptions: {subscriptions}"))
        self.stdout.write(self.style.SUCCESS(f"Payment requests: {payment_requests}"))
        self.stdout.write(self.style.SUCCESS(f"Coin purchases: {purchases}"))
        self.stdout.write(self.style.SUCCESS(f"Profiles updated: {updated_profiles}"))
        self.stdout.write(self.style.SUCCESS(f"Verified accounts: {verified}"))
        self.stdout.write("")
        self.stdout.write("Demo login credentials:")
        for blueprint in STORE_BLUEPRINTS:
            self.stdout.write(f"  - {blueprint['username']} / {blueprint['password']}")
        self.stdout.write("  - demo_admin / Admin@12345")

    def _clear_existing_demo_data(self):
        usernames = [store["username"] for store in STORE_BLUEPRINTS]
        deleted, _ = User.objects.filter(username__in=usernames).delete()
        if deleted:
            self.stdout.write(self.style.WARNING(f"Deleted previous demo records: {deleted}"))

    def _ensure_admin_user(self):
        admin, created = User.objects.get_or_create(
            username="demo_admin",
            defaults={
                "email": "admin@demo.toprice.local",
                "name": "Demo Admin",
                "phone": "0550000001",
                "is_staff": True,
                "is_superuser": True,
                "gender": "male",
                "birthday": date(1987, 1, 1),
            },
        )
        if created or not admin.is_superuser or not admin.is_staff:
            admin.is_staff = True
            admin.is_superuser = True
        admin.name = admin.name or "Demo Admin"
        admin.set_password("Admin@12345")
        admin.save()
        return admin

    def _seed_categories(self):
        categories = {}
        for item in CATEGORY_BLUEPRINTS:
            category, _created = Category.objects.get_or_create(
                name_en=item["name_en"],
                defaults={
                    "name": item["name_en"],
                    "name_ar": item["name_ar"],
                    "name_fr": item["name_fr"],
                    "icon_code_point": item["icon_code_point"],
                    "icon_font_family": "MaterialIcons",
                    "icon_font_package": "",
                    "scarcity_level": item["scarcity_level"],
                },
            )
            changed = False
            for field in ["name", "name_en", "name_ar", "name_fr", "icon_code_point", "scarcity_level"]:
                incoming = item["name_en"] if field == "name" else item[field]
                if getattr(category, field) != incoming:
                    setattr(category, field, incoming)
                    changed = True
            if changed:
                category.save()
            categories[item["key"]] = category
        return categories

    def _seed_stores(self, categories):
        stores = []
        base_join = timezone.now() - timedelta(days=220)
        for index, blueprint in enumerate(STORE_BLUEPRINTS, start=1):
            user, _created = User.objects.get_or_create(
                username=blueprint["username"],
                defaults={
                    "email": blueprint["email"],
                    "name": blueprint["name"],
                    "phone": blueprint["phone"],
                },
            )
            user.email = blueprint["email"]
            user.name = blueprint["name"]
            user.phone = blueprint["phone"]
            user.gender = blueprint["gender"]
            user.birthday = blueprint["birthday"]
            user.address = blueprint["address"]
            user.latitude = blueprint["latitude"]
            user.longitude = blueprint["longitude"]
            user.allow_nearby_visibility = True
            user.location_updated_at = timezone.now() - timedelta(days=90)
            user.store_type = blueprint["store_type"]
            user.store_description = blueprint["store_description"]
            user.facebook = blueprint["facebook"]
            user.instagram = blueprint["instagram"]
            user.whatsapp = blueprint["whatsapp"]
            user.tiktok = ""
            user.youtube = ""
            user.show_phone_public = True
            user.show_social_public = True
            user.coins_balance = 40 + index * 12
            user.date_joined = base_join + timedelta(days=index * 9)
            user.set_password(blueprint["password"])

            if not self.skip_images:
                cover_content = self._download_seeded_image(
                    cache_key=f"{blueprint['username']}-cover",
                    tags=blueprint["cover_tags"],
                    width=1600,
                    height=700,
                )
                if cover_content is not None:
                    user.cover_image.save(
                        f"{blueprint['username'].replace('.', '_')}_cover.jpg",
                        ContentFile(cover_content),
                        save=False,
                    )

                profile_content = self._download_profile_image(blueprint)
                if profile_content is None:
                    profile_content = cover_content
                if profile_content is not None:
                    user.profile_image.save(
                        f"{blueprint['username'].replace('.', '_')}_profile.jpg",
                        ContentFile(profile_content),
                        save=False,
                    )

            user.save()
            UserInterestProfile.objects.update_or_create(
                user=user,
                defaults={
                    "category_scores": {
                        str(categories[blueprint["category_key"]].id): 90,
                    },
                    "preferred_wilayas": [blueprint["wilaya"]],
                    "search_keywords": {blueprint["commune"].lower(): 40, blueprint["wilaya"].lower(): 35},
                },
            )
            stores.append(user)
        return stores

    def _seed_products(self, stores, categories):
        products = []
        for store, blueprint in zip(stores, STORE_BLUEPRINTS):
            product_templates = PRODUCT_TEMPLATES[blueprint["category_key"]]
            category = categories[blueprint["category_key"]]
            image_pool = self._download_product_image_pool(blueprint) if not self.skip_images else []
            for offset, item in enumerate(product_templates, start=1):
                product = Product.objects.create(
                    store=store,
                    category=category,
                    name=item["name"],
                    description=item["description"],
                    price=Decimal(item["price"]),
                    hide_price=False,
                    negotiable=offset % 4 == 0,
                    available_status=Product.AVAILABLE,
                    delivery_available=True,
                    delivery_wilayas=", ".join(blueprint["delivery_wilayas"]),
                )
                created_at = timezone.now() - timedelta(days=(len(product_templates) - offset) * 2 + self.rng.randint(0, 4))
                self._set_field_value(product, "created_at", created_at)

                if image_pool:
                    image_content = image_pool[(offset - 1) % len(image_pool)]
                    if image_content is not None:
                        ProductImage.objects.create(
                            product=product,
                            image=ContentFile(image_content, name=f"{store.username.replace('.', '_')}_{offset}.jpg"),
                            is_main=True,
                        )
                products.append(product)
        return products

    def _seed_promotions(self, stores, products):
        promotions_count = 0
        products_by_store = {}
        for product in products:
            products_by_store.setdefault(product.store_id, []).append(product)

        for index, store in enumerate(stores[:8], start=1):
            target = products_by_store.get(store.id, [])
            if not target:
                continue
            selected = target[index % len(target)]
            Promotion.objects.create(
                store=store,
                product=selected,
                name=f"{selected.name} Flash Offer",
                description=PROMOTION_COPY[index % len(PROMOTION_COPY)],
                percentage=Decimal(str(8 + index * 2)),
                is_active=True,
                start_date=timezone.now() - timedelta(days=index),
                end_date=timezone.now() + timedelta(days=7 + index),
            )
            promotions_count += 1
        return promotions_count

    def _seed_packs(self, stores, products):
        packs_count = 0
        products_by_store = {}
        for product in products:
            products_by_store.setdefault(product.store_id, []).append(product)

        for store, blueprint in zip(stores, STORE_BLUEPRINTS):
            if not blueprint.get("supports_packs"):
                continue
            store_products = products_by_store.get(store.id, [])
            if len(store_products) < 4:
                continue
            pack = Pack.objects.create(
                merchant=store,
                name=f"{store.name} Starter Pack",
                description="Bundle offer built for the demo catalogue.",
                discount=Decimal("2500.00"),
                available_status=Pack.AVAILABLE,
                delivery_available=True,
                delivery_wilayas=store.address.split(",")[-1].strip(),
            )
            target_products_count = 5 if self.rng.random() < 0.35 else 4
            selected_products = self.rng.sample(store_products, k=min(target_products_count, len(store_products)))
            for product in selected_products:
                PackProduct.objects.create(pack=pack, product=product, quantity=1)
            if not self.skip_images:
                image_content = self._download_seeded_image(
                    cache_key=f"{store.username}-pack",
                    tags=blueprint["cover_tags"] + ["bundle"],
                    width=900,
                    height=900,
                )
                if image_content is not None:
                    PackImage.objects.create(
                        pack=pack,
                        image=ContentFile(image_content, name=f"{store.username.replace('.', '_')}_pack.jpg"),
                        is_main=True,
                    )
            packs_count += 1
        return packs_count

    def _seed_favorites(self, stores, products):
        created = 0
        for store in stores:
            options = [product for product in products if product.store_id != store.id]
            self.rng.shuffle(options)
            for product in options[:10]:
                _favorite, was_created = Favorite.objects.get_or_create(user=store, product=product)
                if was_created:
                    created += 1
        return created

    def _seed_followers(self, stores):
        created = 0
        for index, target in enumerate(stores):
            shuffled = stores[:]
            self.rng.shuffle(shuffled)
            for follower in shuffled[:4]:
                if follower.id == target.id:
                    continue
                _relation, was_created = Follower.objects.get_or_create(user=follower, followed_user=target)
                if was_created:
                    created += 1
            if index % 3 == 0:
                extra = stores[(index + 1) % len(stores)]
                if extra.id != target.id:
                    _relation, was_created = Follower.objects.get_or_create(user=extra, followed_user=target)
                    if was_created:
                        created += 1
        return created

    def _seed_interactions(self, stores, products, categories):
        created = 0
        for shopper in stores:
            catalog = [product for product in products if product.store_id != shopper.id]
            self.rng.shuffle(catalog)
            chosen_products = catalog[:18]
            for index, product in enumerate(chosen_products, start=1):
                action = self.rng.choice(
                    ["view", "view", "click", "favorite", "contact", "compare", "share", "rate", "follow_store"]
                )
                timestamp = timezone.now() - timedelta(days=self.rng.randint(0, 25), hours=self.rng.randint(0, 23))
                metadata = {
                    "product_id": product.id,
                    "store_id": product.store_id,
                    "category_id": product.category_id,
                    "discovery_mode": self.rng.choice(["nearby", "location"]),
                    "wilaya_code": product.store.address.split(",")[-1].strip(),
                    "view_duration_sec": self.rng.randint(12, 180),
                    "keyword": product.name.split()[0].lower(),
                    "rating": self.rng.randint(3, 5),
                }
                log = InteractionLog.objects.create(
                    user=shopper,
                    product=product,
                    category=product.category,
                    action=action,
                    metadata=metadata,
                    session_id=f"demo-session-{shopper.id}-{index}",
                )
                self._set_field_value(log, "timestamp", timestamp)
                created += 1

            for _i in range(4):
                category = self.rng.choice(list(categories.values()))
                filter_log = InteractionLog.objects.create(
                    user=shopper,
                    category=category,
                    action=self.rng.choice(["filter_price", "filter_wilaya", "search", "filter_dist"]),
                    metadata={
                        "category_id": category.id,
                        "price_min": self.rng.choice([0, 2000, 5000, 12000]),
                        "price_max": self.rng.choice([15000, 45000, 90000, 150000]),
                        "distance_km": self.rng.choice([5, 15, 30, 60]),
                        "wilaya_code": self.rng.choice([bp["wilaya"] for bp in STORE_BLUEPRINTS]),
                        "keyword": self.rng.choice(["casserole", "chaise", "mouton", "viande", "cahier"]),
                    },
                    session_id=f"demo-filter-{shopper.id}",
                )
                self._set_field_value(
                    filter_log,
                    "timestamp",
                    timezone.now() - timedelta(days=self.rng.randint(0, 20), hours=self.rng.randint(0, 20)),
                )
                created += 1
        return created

    def _seed_reviews(self, stores, products):
        created = 0
        attempts = 0
        while created < 84 and attempts < 600:
            attempts += 1
            reviewer = self.rng.choice(stores)
            product = self.rng.choice(products)
            if reviewer.id == product.store_id:
                continue
            if Review.objects.filter(user=reviewer, product=product).exists():
                continue
            rating = self.rng.choices([5, 4, 3, 2], weights=[35, 30, 20, 15])[0]
            review = Review.objects.create(
                user=reviewer,
                store=product.store,
                product=product,
                rating=rating,
                comment=self.rng.choice(REVIEW_COMMENTS),
            )
            self._set_field_value(
                review,
                "created_at",
                timezone.now() - timedelta(days=self.rng.randint(1, 40), hours=self.rng.randint(0, 23)),
            )
            score = score_review_credibility(reviewer, product.store_id, product.id, rating)
            review.credibility_score = score.score
            review.credibility_level = score.level
            review.is_low_credibility = score.is_low_credibility
            review.evidence_snapshot = score.evidence_snapshot
            review.scored_at = timezone.now()
            review.save(
                update_fields=[
                    "credibility_score",
                    "credibility_level",
                    "is_low_credibility",
                    "evidence_snapshot",
                    "scored_at",
                ]
            )
            created += 1
        return created

    def _seed_reports(self, stores, products):
        store_reports_created = 0
        product_reports_created = 0
        reason_cycle = ["spam", "fake", "fraud", "offensive", "other"]

        store_pairs = []
        for reporter in stores:
            for target in stores:
                if reporter.id != target.id:
                    store_pairs.append((reporter, target))
        self.rng.shuffle(store_pairs)

        for reporter, target in store_pairs[:18]:
            if StoreReport.objects.filter(reporter=reporter, store=target).exists():
                continue
            reason = reason_cycle[store_reports_created % len(reason_cycle)]
            report = StoreReport.objects.create(
                reporter=reporter,
                store=target,
                reason=reason,
                details=STORE_REPORT_TEXTS[reason],
            )
            self._set_field_value(
                report,
                "created_at",
                timezone.now() - timedelta(days=self.rng.randint(0, 25), hours=self.rng.randint(0, 23)),
            )
            score = score_store_report(reporter, target)
            seriousness_score = min(100, score.score + {"fraud": 18, "fake": 12, "offensive": 8, "spam": 6, "other": 4}[reason])
            report.seriousness_score = seriousness_score
            report.seriousness_level = self._score_level(seriousness_score)
            report.is_low_credibility = score.is_low_credibility
            report.evidence_snapshot = score.evidence_snapshot
            report.reporter_reputation_score_at_submission = score.reporter_reputation
            report.scored_at = timezone.now()
            report.status = self._report_status_from_score(score.score, store_reports_created)
            report.save(
                update_fields=[
                    "seriousness_score",
                    "seriousness_level",
                    "is_low_credibility",
                    "evidence_snapshot",
                    "reporter_reputation_score_at_submission",
                    "scored_at",
                    "status",
                ]
            )
            store_reports_created += 1

        product_choices = products[:]
        self.rng.shuffle(product_choices)
        product_pairs = []
        for reporter in stores:
            for product in product_choices:
                if product.store_id != reporter.id:
                    product_pairs.append((reporter, product))
        self.rng.shuffle(product_pairs)

        for reporter, product in product_pairs[:32]:
            if ProductReport.objects.filter(reporter=reporter, product=product).exists():
                continue
            reason = reason_cycle[product_reports_created % len(reason_cycle)]
            report = ProductReport.objects.create(
                reporter=reporter,
                product=product,
                reason=reason,
                details=PRODUCT_REPORT_TEXTS[reason],
            )
            self._set_field_value(
                report,
                "created_at",
                timezone.now() - timedelta(days=self.rng.randint(0, 25), hours=self.rng.randint(0, 23)),
            )
            score = score_product_report(reporter, product.id, product.store_id)
            seriousness_score = min(100, score.score + {"fraud": 20, "fake": 14, "offensive": 7, "spam": 5, "other": 4}[reason])
            report.seriousness_score = seriousness_score
            report.seriousness_level = self._score_level(seriousness_score)
            report.is_low_credibility = score.is_low_credibility
            report.evidence_snapshot = score.evidence_snapshot
            report.reporter_reputation_score_at_submission = score.reporter_reputation
            report.scored_at = timezone.now()
            report.status = self._report_status_from_score(score.score, product_reports_created)
            report.save(
                update_fields=[
                    "seriousness_score",
                    "seriousness_level",
                    "is_low_credibility",
                    "evidence_snapshot",
                    "reporter_reputation_score_at_submission",
                    "scored_at",
                    "status",
                ]
            )
            product_reports_created += 1

        return store_reports_created, product_reports_created

    def _seed_feedback(self, stores):
        created = 0
        for index, (kind, message, status_value) in enumerate(FEEDBACK_ITEMS, start=1):
            user = stores[(index - 1) % len(stores)]
            feedback = Feedback.objects.create(
                user=user,
                type=kind,
                message=message,
                app_version="1.0.0-demo",
                platform="android",
                device_info=self.rng.choice(["Galaxy A54", "Redmi Note 12", "iPhone 13", "Infinix Note 40"]),
                status=status_value,
                admin_note="Seeded for moderation and support testing.",
            )
            self._set_field_value(
                feedback,
                "created_at",
                timezone.now() - timedelta(days=self.rng.randint(0, 18), hours=self.rng.randint(0, 12)),
            )
            created += 1
        return created

    def _seed_subscriptions(self, admin_user, stores):
        bootstrap_default_subscription_plans()
        plan_map = {plan.slug: plan for plan in SubscriptionPlan.objects.all()}
        SubscriptionPaymentConfig.objects.all().update(is_active=False)
        SubscriptionPaymentConfig.objects.create(
            rib="00799999004129827780",
            instructions="Transfer the subscription amount, upload proof, and include the merchant username for fast review.",
            is_active=True,
        )

        active_assignments = [
            (stores[0], "bazaar-plus", 18),
            (stores[1], "atlas-pro", 22),
            (stores[5], "bazaar-plus", 14),
            (stores[8], "souk-starter", 9),
        ]
        subscriptions = 0
        for store, slug, started_days_ago in active_assignments:
            plan = plan_map[slug]
            MerchantSubscription.objects.update_or_create(
                store=store,
                defaults={
                    "plan": plan,
                    "start_date": timezone.now() - timedelta(days=started_days_ago),
                    "end_date": timezone.now() + timedelta(days=plan.duration_days - started_days_ago),
                    "status": "active",
                },
            )
            subscriptions += 1

        request_specs = [
            (stores[2], "atlas-pro", SubscriptionPaymentRequest.STATUS_APPROVED, ""),
            (stores[3], "souk-starter", SubscriptionPaymentRequest.STATUS_PENDING, ""),
            (stores[6], "bazaar-plus", SubscriptionPaymentRequest.STATUS_REJECTED, SubscriptionPaymentRequest.REASON_UNREADABLE_PROOF),
        ]
        created_requests = 0
        for store, slug, status_value, reason_code in request_specs:
            plan = plan_map[slug]
            request = SubscriptionPaymentRequest.objects.create(
                merchant=store,
                plan=plan,
                status=status_value,
                payment_note=f"Subscription request for {store.username}.",
                status_reason_code=reason_code,
                status_reason_text="Proof was blurry; merchant asked to resubmit." if status_value == SubscriptionPaymentRequest.STATUS_REJECTED else "",
                reviewed_by=admin_user if status_value != SubscriptionPaymentRequest.STATUS_PENDING else None,
                reviewed_at=timezone.now() - timedelta(days=1) if status_value != SubscriptionPaymentRequest.STATUS_PENDING else None,
            )
            if not self.skip_images:
                proof_content = self._download_seeded_image(
                    cache_key=f"subscription-proof-{store.username}",
                    tags=["receipt", "payment", "document"],
                    width=1000,
                    height=700,
                )
                if proof_content is not None:
                    SubscriptionPaymentProof.objects.create(
                        payment_request=request,
                        image=ContentFile(proof_content, name=f"{store.username.replace('.', '_')}_subscription_proof.jpg"),
                    )
            created_requests += 1
        return subscriptions, created_requests

    def _seed_wallet(self, admin_user, stores):
        created = 0
        for pack_blueprint in COIN_PACK_BLUEPRINTS:
            CoinPackPlan.objects.update_or_create(
                pack_id=pack_blueprint["pack_id"],
                defaults=pack_blueprint,
            )

        for index, store in enumerate(stores[:4], start=1):
            purchase = CoinPurchase.objects.create(
                user=store,
                pack_id=COIN_PACK_BLUEPRINTS[index - 1]["pack_id"],
                coins_amount=COIN_PACK_BLUEPRINTS[index - 1]["coins_amount"],
                price_amount=Decimal(COIN_PACK_BLUEPRINTS[index - 1]["price_amount"]),
                payment_note=f"Wallet top-up request by {store.username}.",
                status=CoinPurchase.STATUS_PENDING,
            )
            if not self.skip_images:
                proof_content = self._download_seeded_image(
                    cache_key=f"wallet-proof-{store.username}",
                    tags=["bank", "transfer", "receipt"],
                    width=1000,
                    height=700,
                )
                if proof_content is not None:
                    CoinPurchaseProof.objects.create(
                        purchase=purchase,
                        image=ContentFile(proof_content, name=f"{store.username.replace('.', '_')}_wallet_proof.jpg"),
                    )
            if index <= 3:
                approve_coin_purchase(purchase, approver=admin_user)
                grant_coins(store, amount=15 * index, reason="demo_bonus")
            created += 1
        return created

    def _seed_settings_and_verifications(self, admin_user, stores):
        system = SystemSettings.get_settings()
        system.first_login_coins = 25
        system.daily_login_coins = 8
        system.save()

        trust = TrustSettings.get_settings()
        trust.report_quick_submit_seconds = 18
        trust.review_quick_submit_seconds = 22
        trust.minimum_interactions_for_high_credibility = 4
        trust.reporter_reputation_default = 60
        trust.reporter_reputation_low_quality_penalty = 10
        trust.reporter_reputation_good_report_bonus = 4
        trust.report_weight_interactions = 42
        trust.report_weight_recency = 18
        trust.report_weight_reputation = 20
        trust.report_weight_account_age = 20
        trust.review_weight_dwell = 32
        trust.review_weight_interactions = 38
        trust.review_weight_account_age = 15
        trust.review_weight_history = 15
        trust.verified_min_credible_positive_reviews = 6
        trust.verified_max_credible_negative_ratio_percent = 25
        trust.verified_min_account_age_days = 30
        trust.auto_verify_eligible_stores = False
        trust.report_cooldown_minutes = 15
        trust.review_cooldown_minutes = 7
        trust.max_reports_per_day = 12
        trust.analytics_retention_days = 180
        trust.save()

        for store in stores:
            evaluate_store_verification(store)

        verified_usernames = {
            "dar.ouani.hydra",
            "sarah.mode.annaba",
            "yacine.mobile.babez",
            "lina.beaute.bejaia",
        }
        verified_count = 0
        for store in stores:
            if store.username in verified_usernames:
                store.verification_status = "verified"
                store.is_verified = True
                store.verified_by = admin_user
                store.verified_at = timezone.now() - timedelta(days=self.rng.randint(2, 18))
                store.verification_note = "Documents manually checked for demo readiness."
                verified_count += 1
            elif store.username in {"atlas.meuble.setif", "maktabati.tlemcen"}:
                store.verification_status = "eligible"
                store.is_verified = False
                store.verified_by = None
                store.verified_at = None
                store.verification_note = "Eligible based on activity and positive review history."
            elif store.username in {"soug.elmawashi.khroub", "aya.accessoires.blida"}:
                store.verification_status = "pending"
                store.is_verified = False
                store.verified_by = None
                store.verified_at = None
                store.verification_note = "Pending document review."
            else:
                store.verification_status = "none"
                store.is_verified = False
                store.verified_by = None
                store.verified_at = None
                store.verification_note = ""
            store.save(
                update_fields=[
                    "verification_status",
                    "is_verified",
                    "verified_by",
                    "verified_at",
                    "verification_note",
                ]
            )
        return verified_count

    def _download_product_image_pool(self, blueprint):
        pool = []
        for index, tags in enumerate(blueprint.get("product_image_queries") or [], start=1):
            content = self._download_seeded_image(
                cache_key=f"{blueprint['username']}-product-pool-{index}",
                tags=tags,
                width=900,
                height=900,
            )
            if content is not None:
                pool.append(content)
        return pool

    def _download_profile_image(self, blueprint):
        tags = []
        for query in blueprint.get("product_image_queries") or []:
            if isinstance(query, (list, tuple)):
                tags.extend(str(tag).strip() for tag in query if str(tag).strip())
            else:
                value = str(query).strip()
                if value:
                    tags.append(value)

        if not tags:
            tags.extend(str(tag).strip() for tag in (blueprint.get("cover_tags") or []) if str(tag).strip())

        tag_string = ",".join(dict.fromkeys(tags))
        if not tag_string:
            return None

        seed = f"profile-{blueprint['username']}-{tag_string.replace(',', '-')}"
        urls = [f"https://loremflickr.com/700/700/{tag_string}?lock={urllib.parse.quote(seed)}"]
        return self._download_from_sources(urls, cache_key=f"profile-{blueprint['username']}")

    def _download_seeded_image(self, cache_key, tags, width, height):
        tag_string = ",".join(str(tag).strip().replace(" ", ",") for tag in tags if str(tag).strip())
        seed = f"{cache_key}-{tag_string.replace(',', '-')}" if tag_string else cache_key
        urls = []
        if tag_string:
            urls.append(f"https://loremflickr.com/{width}/{height}/{tag_string}?lock={urllib.parse.quote(seed)}")
        urls.append(f"https://picsum.photos/seed/{urllib.parse.quote(seed)}/{width}/{height}")
        content = self._download_from_sources(urls, cache_key=cache_key)
        if content is not None:
            self.image_fallback_cache[cache_key] = content
            return content
        for fallback in self.image_fallback_cache.values():
            return fallback
        return None

    def _download_from_sources(self, urls, cache_key):
        if self.skip_images:
            return None
        if cache_key in self.download_cache:
            return self.download_cache[cache_key]
        for url in urls:
            try:
                request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(request, timeout=self.download_timeout) as response:
                    content = response.read()
                    if content:
                        self.download_cache[cache_key] = content
                        return content
            except (urllib.error.URLError, TimeoutError, ValueError):
                continue
        return None

    def _set_field_value(self, instance, field_name, value):
        instance.__class__.objects.filter(pk=instance.pk).update(**{field_name: value})
        setattr(instance, field_name, value)

    def _score_level(self, score):
        if score >= 70:
            return "high"
        if score >= 40:
            return "medium"
        return "low"

    def _report_status_from_score(self, credibility_score, index):
        if credibility_score < 35:
            return "rejected"
        if index % 4 == 0:
            return "reviewed"
        return "pending"
