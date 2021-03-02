#ifndef FIFO_H
#define FIFO_H

#include "stdint.h"

//-------------------------------------------------------------------
#define FIFO(data_type, size) \
  struct \
  { \
    data_type data[size]; \
    int_fast16_t head; \
    int_fast16_t tail; \
  }

//-------------------------------------------------------------------
#define FIFO_INIT(fifo) \
    do { \
        (fifo).head = 0; \
        (fifo).tail = 0; \
    } while(0)

#define FIFO_SIZE(fifo)   (sizeof(fifo.data)/sizeof(fifo.data[0]))

#define FIFO_EMPTY(fifo)  ((fifo).head == (fifo).tail)

#define FIFO_BUSY(fifo)   ((FIFO_SIZE(fifo) + (fifo).head - (fifo).tail) % FIFO_SIZE(fifo))

#define FIFO_FREE(fifo)   (((FIFO_SIZE(fifo)-1) - (fifo).head + (fifo).tail) % FIFO_SIZE(fifo))

#define FIFO_FULL(fifo)   ((((fifo).head + 1) % FIFO_SIZE(fifo)) == (fifo).tail)

#define FIFO_PUT(fifo, item) \
    do { \
        if(!FIFO_FULL(fifo)) \
        { \
            (fifo).data[(fifo).head] = (item); \
            (fifo).head = ((fifo).head + 1) % FIFO_SIZE(fifo); \
        } \
    } while(0)

// fast does not check fifo is full
#define FIFO_PUT_FAST(fifo, item) \
    do { \
        (fifo).data[(fifo).head] = (item); \
        (fifo).head = ((fifo).head + 1) % FIFO_SIZE(fifo); \
    } while(0)

#define FIFO_GET(fifo, item) \
    do { \
        if(!FIFO_EMPTY(fifo)) \
        { \
            (item) = (fifo).data[(fifo).tail]; \
            (fifo).tail = ((fifo).tail + 1) % FIFO_SIZE(fifo); \
        } \
    } while(0)

#define FIFO_TAIL(fifo, item) \
    do { \
        if(!FIFO_EMPTY(fifo)) \
        { \
            (item) = (fifo).data[(fifo).tail]; \
        } \
    } while(0)

#endif // FIFO_H
