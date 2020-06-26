from django.urls  import path
from APIView import views


urlpatterns = [
    path('hello-view/',views.HelloApiView.as_view()),
]
