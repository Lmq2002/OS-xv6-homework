// Buffer cache.
//
// The buffer cache is a linked list of buf structures holding
// cached copies of disk block contents.  Caching disk blocks
// in memory reduces the number of disk reads and also provides
// a synchronization point for disk blocks used by multiple processes.
//
// Interface:
// * To get a buffer for a particular disk block, call bread.
// * After changing buffer data, call bwrite to write it to disk.
// * When done with the buffer, call brelse.
// * Do not use the buffer after calling brelse.
// * Only one process at a time can use a buffer,
//     so do not keep them longer than necessary.


#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"

#define NBUC 13
extern uint ticks;

struct {
  struct spinlock lock;
  struct buf buf[NBUF];

  int size;
  struct buf buckets[NBUC];
  struct spinlock locks[NBUC];
  struct spinlock hashlock;

} bcache;

// struct bucket {
//   struct spinlock lock;
//   struct buf head;
// };

// static struct bucket hashTable[NBUC];



void
binit(void)
{
  struct buf *b;
  
  bcache.size = 0;
  initlock(&bcache.lock, "bcache");
  initlock(&bcache.hashlock, "bcache.hash");

  for(b = bcache.buf; b < bcache.buf+NBUF; b++)
  {
    initsleeplock(&b->lock, "buffer");
  }
  for(int i=0; i<NBUC; i++)
  {
    initlock(&bcache.locks[i],"bcache.bucket");
    
  }
}

// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;

  uint64 hash = blockno%NBUC;
  struct buf *pre, *minb, *minpre;
  uint mintick;

  acquire(&bcache.locks[hash]);
  
  // Is the block already cached?
  for(b = bcache.buckets[hash].next; b; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      b->refcnt++;
      release(&bcache.locks[hash]);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // Not cached.
  // Recycle the least recently used (LRU) unused buffer.
  acquire(&bcache.lock);
  if(bcache.size<NBUF)
  {
    b = &bcache.buf[bcache.size++];
    release(&bcache.lock);
    b->dev =dev;
    b->blockno =blockno;
    b->valid = 0;
    b->refcnt =1;
    b->next =bcache.buckets[hash].next;
    bcache.buckets[hash].next = b;
    release(&bcache.locks[hash]);
    acquiresleep(&b->lock);
    return b;
  }
  release(&bcache.lock);
  release(&bcache.locks[hash]);

  acquire(&bcache.hashlock);
  for(int i=0; i<NBUC; i++)
  {
    mintick = -1;
    acquire(&bcache.locks[hash]);
    for(pre = &bcache.buckets[hash], b = pre->next; b; pre = b, b = b->next)
    {
      if(hash == blockno%NBUC &&b->dev == dev && b->blockno == blockno)
      {
        b->refcnt++;
        release(&bcache.locks[hash]);
        release(&bcache.hashlock);
        acquiresleep(&b->lock);
        return b;
      }
      if(b->refcnt == 0 && b->tick<mintick)
      {
        minb = b;
        minpre = pre;
        mintick = b->tick;
      }
    }
    if(minb)
    {
      minb->dev = dev;
      minb->blockno = blockno;
      minb->valid = 0;
      minb->refcnt =1;
      if(hash !=blockno%NBUC)
      {
        minpre->next = minb->next;
        release(&bcache.locks[hash]);
        hash = blockno%NBUC;
        acquire(&bcache.locks[hash]);
        minb->next = bcache.buckets[hash].next;
        bcache.buckets[hash].next = minb;
      }
      release(&bcache.locks[hash]);
      release(&bcache.hashlock);
      acquiresleep(&minb->lock);
      return minb;
    }
    release(&bcache.locks[hash]);
    hash++;
    if(hash == NBUC)
    {
      hash =0;
    }
  }
  panic("bget: no buffers");
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("bwrite");
  virtio_disk_rw(b, 1);
}

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("brelse");

  releasesleep(&b->lock);

  uint64 hash = b->blockno%NBUC;
  acquire(&bcache.locks[hash]);
  b->refcnt--;
  if(b->refcnt == 0)
    b->tick = ticks;
  release(&bcache.locks[hash]);
}

void
bpin(struct buf *b) {
  uint64 hash = b->blockno%NBUC;
  acquire(&bcache.locks[hash]);
  b->refcnt++;
  release(&bcache.locks[hash]);
}

void
bunpin(struct buf *b) {
  uint64 hash = b->blockno%NBUC;
  acquire(&bcache.locks[hash]);
  b->refcnt--;
  release(&bcache.locks[hash]);
}