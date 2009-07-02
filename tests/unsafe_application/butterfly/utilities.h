#ifndef __UTILITIES_H
#define __UTILITIES_H

#define set_bit(reg, bit) (reg |= (1 << bit))
#define clear_bit(reg, bit) (reg &= ~(1 << bit))
#define test_bit(reg, bit) (reg & (1 << bit))
#define loop_until_bit_set(reg, bit)   while(!test_bit(reg, bit))
#define loop_until_bit_clear(reg, bit) while( test_bit(reg, bit))

typedef unsigned char bool_t;

#define TRUE  1
#define FALSE 0

#endif
