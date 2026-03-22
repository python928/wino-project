from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('wallet', '0006_coinpackplan_coin_type_optional_default'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='coinpackplan',
            name='coin_type',
        ),
        migrations.RemoveField(
            model_name='coinpurchase',
            name='coin_type',
        ),
        migrations.RemoveField(
            model_name='cointransaction',
            name='coin_type',
        ),
    ]
