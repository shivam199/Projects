from django.db import models


class Task(models.Model):
    title=models.CharField(max_length=150)
    complete=models.BooleanField()
    created=models.DateField(auto_now_add=True)
    

    def __str__(self):
        return self.title
    
