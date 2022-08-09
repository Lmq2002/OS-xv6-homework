#include"../kernel/types.h"
#include"../user/user.h"
#include"stddef.h"


#define MSGMAX 35


int main(int argc,char* argv)
{
    int pd[2];
    int pid;
    int num[MSGMAX+1];
    int index =0;

    for(int i=2;i<=MSGMAX;i++)
    {
        num[index++]=i;
    }

    while(1)
    {
        pipe(pd);
        if((pid = fork())<0)
        {
            fprintf(2,"fork error\n");
            exit(0);
        }
        else if(pid>0)//父进程
        {
            //写管道
            close(pd[0]);
            for(int i=0; i<index; i++)
            {
                write(pd[1],&num[i],sizeof(int));
            }
            close(pd[1]);
            wait(NULL);
            exit(0);
        }
        else//子进程
        {
            //判断倍数
            close(pd[1]);

            index = 0;
            int prime;
            int t;

            if(read(pd[0],&prime,sizeof(int)))
            {
                printf("prime: %d\n",prime);
            }
            else
                break;
            while(read(pd[0],&t,sizeof(int)))
            {
                if(t%prime)
                {
                    num[index++]=t;
                }
            }
            close(pd[0]);
        }
    }
    exit(0);
}