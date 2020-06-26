from django.shortcuts import render
from .models import Destination

# Create your views here.
def home(request):
    dest1 = Destination()
    dest1.name= 'Mumbai'
    dest1.desc= 'City that nevew sleep'
    dest1.img= 'destination_1.jpg'
    dest1.price= 530
    dest1.offer=True
    
    dest2 = Destination()
    dest2.name= 'Chennai'
    dest2.desc= 'also known as Madras'
    dest2.img= 'destination_2.jpg'
    dest2.price= 530
    dest2.offer= False

    dest3 = Destination()
    dest3.name= 'Delhi'
    dest3.desc= 'Capital City, Always welcome you with warm hrart '
    dest3.img= 'destination_3.jpg'
    dest3.price= 530
    dest3.offer= False
    
    dests=[dest1,dest2,dest3]
    return render(request,'index.html',{'dests':dests})