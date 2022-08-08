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
} bcache;

struct bucket {
  struct spinlock lock;
  struct buf head;
};

static struct bucket hashTable[NBUC];

void
replacebuf(struct buf *lrubuf,uint dev, uint blockno)
{
  lrubuf->dev = dev;
  lrubuf->blockno = blockno;
  lrubuf->valid = 0;
  lrubuf->refcnt = 1;
  lrubuf->tick =ticks;
}

void
binit(void)
{
  struct buf *b;

  initlock(&bcache.lock, "bcache");

  for(b = bcache.buf; b < bcache.buf+NBUF; b++)
  {
    initsleeplock(&b->lock, "buffer");
    b->tick = 0;
  }
  for(int i=0; i<NBUC; i++)
  {
    initlock(&hashTable[i].lock,"bcache.bucket");
    hashTable[i].head.next = 0;
    hashTable[i].head.prev = 0;
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
  acquire(&hashTable[hash].lock);
  
  // Is the block already cached?
  for(b = hashTable[hash].head.next; b; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      b->refcnt++;
      release(&hashTable[hash].lock);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // Not cached.
  // Recycle the least recently used (LRU) unused buffer.
  acquire(&bcache.lock);
  struct buf *lrubuf = 0;
  uint64 mintick = 0;
  for(b = bcache.buf; b <bcache.buf+NBUF; b++){
    if(b->refcnt == 0) 
    {
      if(lrubuf ==0)
      {
        lrubuf = b;
        mintick = b->tick;
        continue;
      }
      if(b->tick<mintick)
      {
        lrubuf = b;
        mintick = b->tick;
      }
    }
  }
  if(lrubuf)
  {
    uint64 oldtick = lrubuf->tick;
    uint64 oldblockno = lrubuf->blockno;
    if(oldtick == 0)
    {
      replacebuf(lrubuf,dev,blockno);
    }
    else
    {
      if(hash != oldblockno%NBUC)
      {
        if(holding(&hashTable[oldblockno%NBUC].lock))
          panic("???");
        acquire(&hashTable[oldblockno%NBUC].lock);
        replacebuf(lrubuf,dev,blockno);
        lrubuf->prev->next = lrubuf->next;
        if(lrubuf->next)
          lrubuf->next->prev = lrubuf->prev;
        release(&hashTable[oldblockno%NBUC].lock);
      }
      else
      {
        replacebuf(lrubuf,dev,blockno);
        release(&bcache.lock);
        release(&hashTable[hash].lock);
        acquiresleep(&lrubuf->lock);
        return lrubuf;
      }
    }
    lrubuf->next = hashTable[hash].head.next;
    lrubuf->prev = &hashTable[hash].head;
    if(hashTable[hash].head.next)
      hashTable[hash].head.next->prev = lrubuf;
    hashTable[hash].head.next = lrubuf;
    
    release(&bcache.lock);
    release(&hashTable[hash].lock);
    acquiresleep(&lrubuf->lock);
    return lrubuf;
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
  acquire(&hashTable[hash].lock);
  b->refcnt--;
  release(&hashTable[hash].lock);
}

void
bpin(struct buf *b) {
  uint64 hash = b->blockno%NBUC;
  acquire(&hashTable[hash].lock);
  b->refcnt++;
  release(&hashTable[hash].lock);
}

void
bunpin(struct buf *b) {
  uint64 hash = b->blockno%NBUC;
  acquire(&hashTable[hash].lock);
  b->refcnt--;
  release(&hashTable[hash].lock);
}


