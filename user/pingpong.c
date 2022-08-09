#include"../kernel/types.h"
#include"../user/user.h"
#include"stddef.h"

int main(int argc, char* argv[])
{
    int p_pd[2], c_pd[2];
    char buf[8];
    int pid;

    pipe(p_pd);
    pipe(c_pd);

    if((pid=fork())==0)//创建的是子进程，即子进程写给父进程
    {
        read(p_pd[0],(void*)buf,sizeof(char*));
        printf("%d: received %s\n", getpid(), buf);
        write(c_pd[1],"pong",strlen("pong"));
    }
    else
    {
        write(p_pd[1],"ping",strlen("ping"));
        pid=wait(NULL);
        read(c_pd[0],(void*)buf,sizeof(char*));
        printf("%d: received %s\n", getpid(), buf);
    }
    exit(0);
}