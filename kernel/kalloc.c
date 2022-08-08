// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

struct run *popr(int id);//缩空闲列表
void pushr(int id,struct run *r);//增r头块到空闲列表id,

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

/*
struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

void
kinit()
{
  initlock(&kmem.lock, "kmem");
  freerange(end, (void*)PHYSTOP);
}
*/

struct kmem{
  struct spinlock lock;
  struct run *freelist;
};

struct kmem kmems[NCPU];

void 
kinit()
{
  for(int i=0;i<NCPU;i++)
    initlock(&kmems[i].lock,"kmem");
  freerange(end,(void*)PHYSTOP);
}


void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)

/*
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}
*/

//释放pa块
void
kfree(void *pa)
{
  //新的空闲链表
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  //获取当前内核id
  push_off();
  int currentid=cpuid();
  pop_off();

  acquire(&kmems[currentid].lock);
  r->next = kmems[currentid].freelist;
  kmems[currentid].freelist = r;
  release(&kmems[currentid].lock);

}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
/*
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}
*/

//分配某块，返回该块
void *
kalloc(void)
{
  struct run *r;
  
  //标志是否偷盗,0为否，1为是
  int issteal =0;

  //获取当前id
  push_off();
  int currentid = cpuid();
  pop_off();

  acquire(&kmems[currentid].lock);

  /*先尝试改变当前cpu的空闲列表
  * 如果空闲列表为空，那么进行偷的操作
  * 对除了当且id的每个id列表进行检查，如果找到有列表不为空，
  * 就令r等于要分配的块，并交由当前id的空闲列表。
  * 然后再取出来分配出去。
  */
  r = popr(currentid);//返回值为原列表
  if(!r)//原列表是空的
  {
    for(int id=0;id<NCPU;id++)
    {
      if(id==currentid)continue;
      if(kmems[id].freelist)//有空闲块
      {
        acquire(&kmems[id].lock);
        r=popr(id);
        pushr(currentid,r);
        release(&kmems[id].lock);

        issteal = 1;
        break;
      }
    }
  }

  if(issteal)
    r=popr(currentid);

  release(&kmems[currentid].lock);

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}

struct run *
popr(int id)
{
  struct run *r;
  r =kmems[id].freelist;
  if(r)
    kmems[id].freelist=r->next;
  return r;
}

void 
pushr(int id, struct run *r)
{
  if(r){
    r->next=kmems[id].freelist;
    kmems[id].freelist = r;
  }
  else{
    panic("cannot push null run");
  }
}
