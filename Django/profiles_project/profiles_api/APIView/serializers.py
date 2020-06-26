from rest_framework import serializers
from APIView import models


class HelloSerializer(serializers.Serializer):
    """Serializer  a name field for testing our APIView"""
    name=serializers.CharField(max_length=10)


class UserProfileSerializer(serializers.ModelSerializer):
    """Serializes user profile object"""
    class Meta: 
         model= models.UserProfile
         fields = ('id','name','email','password')
         extra_kwargs = {
             'password':{
                'write_only': True,
                'style' :  {'input_type': 'password'}
             }

         } 

    def create(self, validated_data):
        """ create and return new user profile"""



         
