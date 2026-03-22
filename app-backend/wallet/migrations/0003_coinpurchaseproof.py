from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('wallet', '0002_coinpurchase_approval_fields'),
    ]

    operations = [
        migrations.CreateModel(
            name='CoinPurchaseProof',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('image', models.ImageField(upload_to='wallet/purchase_proofs/')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('purchase', models.ForeignKey(on_delete=models.deletion.CASCADE, related_name='proofs', to='wallet.coinpurchase')),
            ],
            options={
                'ordering': ['created_at'],
            },
        ),
    ]
