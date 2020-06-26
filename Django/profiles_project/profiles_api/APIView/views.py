from rest_framework.views import APIView
from  rest_framework.response import Response
from rest_framework import status
from APIView import serializers




class HelloApiView(APIView):
    """Test API View"""

    serializer_class = serializers.HelloSerializer



    def get(self, request, format=None):
        """Return a list of API features"""
        an_apiview = [
            "User HTTp methods get, put, post, delete method",
            "very similar to previous Django view",
            "gives you more control on api logic",
            'Is mapped to manually to urls'
        ]

        return Response({'message':"hello", "an_apiview": an_apiview} )



    def post(self, request):
        """ create a message using name"""
        serializer = self.serializer_class(data=request.data)

        if serializer.is_valid():
            name=serializer.validated_data.get('name')
            message = f'Hello {name}'
            return Response({'message':message})
        else:
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
                )

