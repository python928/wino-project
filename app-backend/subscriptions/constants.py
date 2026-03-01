DEFAULT_SUBSCRIPTION_RIB = '00799999004129827780'
DEFAULT_SUBSCRIPTION_INSTRUCTIONS = (
	'Send money to this RIB and submit payment confirmation.'
)

DEFAULT_SUBSCRIPTION_PLANS = [
	{
		'name': 'Starter Plan',
		'slug': 'starter',
		'max_products': 25,
		'price': '10000.00',
		'duration_days': 30,
		'benefits': 'Up to 25 posts per month\nPriority review for approval\nBasic support',
		'is_active': True,
	},
	{
		'name': 'Business Plan',
		'slug': 'business',
		'max_products': 80,
		'price': '10000.00',
		'duration_days': 30,
		'benefits': 'Up to 80 posts per month\nPriority listing boost\nFaster support',
		'is_active': True,
	},
	{
		'name': 'Pro Plan',
		'slug': 'pro',
		'max_products': 200,
		'price': '10000.00',
		'duration_days': 30,
		'benefits': 'Up to 200 posts per month\nTop exposure slots\nVIP support',
		'is_active': True,
	},
]
