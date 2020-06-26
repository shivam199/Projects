from rest_framework import serializers
from .models import Destination

class DestinationSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100)
    imag = serializers.ImageField(upload_to='pics')
    desc = serializers.TextField()
    price = serializers.IntegerField()
    offer = serializers.BooleanField(default=False)


    def create(self,validated_data):
        return Destination.objects.create(validated_data)

    def update(self,validated_data):
        instance.name = validated_data.get('name',instance.name)
        instance.desc = validated_data.get('desc',instance.desc)
        instance.price = validated_data.get('price',instance.price)
        instance.price = validated_data.get('offer',instance.offer)
        instance.save()
        return instance