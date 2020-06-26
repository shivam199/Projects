from django.shortcuts import render,redirect
from django.http import HttpResponse
from .models import Task
from .forms import TaskForm
def index(request):
    tasks = Task.objects.all()
    form= TaskForm()
    context={'tasks':tasks, 'form':form}


    if request.method == 'POST':
        form=TaskForm(request.POST)
        if form.is_valid():
            form.save()

    return render(request, 'tasks/list.html',context)


def update(request,pk):
    val = Task.objects.get(title=pk)
   

    return render(request, 'tasks/update.html',{'form':val})


def comeback(request,pk):
    obj = Task.objects.get(title=pk)
    obj.title=request.POST['title']
    return redirect(index)

    
