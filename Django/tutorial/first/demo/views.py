# from django.shortcuts import render
# from django.http import HttpResponse
# from django.views import View
from .models import Book
from rest_framework import viewsets
from .seriallizers import BookSerializer


class BookViewSet(viewsets.ModelViewSet):
    serializer_class = BookSerializer
    queryset = Book.objects.all()



# class Another(View):

#     book = Book.objects.all()
#     output=''
#     for b in book:
#         output += 'this is '+str(b.title)+ '<br>'

#     def get(self, request):
#         return HttpResponse(self.output)
        


# def first(request):
#     return HttpResponse('hey, this response from first')


# def template(request):
#     books= Book.objects.all()
#     return render(request,'dynamic.html',{'books':books})


