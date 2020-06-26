from django.db import models

class Book(models.Model):
    title=models.CharField(max_length=100, unique=True)
    description=models.TextField(max_length=100, blank=True)
    price=models.DecimalField(default=0, max_digits=3, decimal_places=2)
    published=models.DateField(blank=True, null=True)
    is_published=models.BooleanField(default=True)
    cover=models.ImageField(upload_to='covers/', blank=True)

