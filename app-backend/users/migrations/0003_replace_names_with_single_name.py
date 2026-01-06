# Generated manually to replace first_name, last_name, display_name with name

from django.db import migrations, models


def migrate_names_forward(apps, schema_editor):
    """Migrate existing first_name, last_name, display_name to single name field"""
    User = apps.get_model('users', 'User')
    for user in User.objects.all():
        # Priority: display_name > first_name + last_name > username
        if user.display_name:
            user.name = user.display_name
        elif user.first_name or user.last_name:
            user.name = f"{user.first_name} {user.last_name}".strip()
        else:
            user.name = user.username
        user.save(update_fields=['name'])


def migrate_names_backward(apps, schema_editor):
    """Migrate name back to display_name for rollback"""
    User = apps.get_model('users', 'User')
    for user in User.objects.all():
        if user.name:
            user.display_name = user.name
            # Try to split name into first and last
            parts = user.name.split(' ', 1)
            user.first_name = parts[0] if parts else ''
            user.last_name = parts[1] if len(parts) > 1 else ''
            user.save(update_fields=['display_name', 'first_name', 'last_name'])


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0002_user_display_name'),
    ]

    operations = [
        # Step 1: Add name field with temporary default
        migrations.AddField(
            model_name='user',
            name='name',
            field=models.CharField(default='User', max_length=255),
            preserve_default=False,
        ),

        # Step 2: Migrate data from old fields to new name field
        migrations.RunPython(migrate_names_forward, migrate_names_backward),

        # Step 3: Remove old display_name field
        migrations.RemoveField(
            model_name='user',
            name='display_name',
        ),

        # Note: first_name and last_name are inherited from AbstractUser
        # We override them in the model with None to disable them
    ]
