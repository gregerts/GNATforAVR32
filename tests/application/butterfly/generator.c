/* Quasi random signal generator */

#include <avr/io.h>
#include <avr/interrupt.h>

#define set_bit(reg, bit) (reg |= (1 << bit))
#define clear_bit(reg, bit) (reg &= ~(1 << bit))

static unsigned long iseed = 1;

int main()
{
  /* Interrupt sampling frequency */
  const int freq = 800;

  /* Set up PORTD0 as output */
  set_bit(DDRD, PIN0);

  /* Set up timer 0 for interrupting at freq
   *
   * Prescaler = 256
   * Compare   = 8 MHz / (256 * freq) + 1
   */
  OCR0A  = 8000000L / (256L * freq) + 1;
  TCCR0A = (1 << WGM01) | (4 << CS00);
  TIMSK0 = (1 << OCIE0A);

  /* Enable interrupts */
  sei();

  /* Loop forever... */
  while (1);

  return 0;
}

ISR(TIMER0_COMP_vect)
{
  /* Algorithm from "Numerical Recipes in C++" 2.nd ed. pg. 302 */

  const unsigned long IB1 = 1, IB2 = 2, IB5 = 16, IB18 = 131072;
  const unsigned long MASK = IB1 + IB2 + IB5;

  if (iseed & IB18)
    {
      iseed = ((iseed ^ MASK) << 1) | IB1;      
      set_bit(PORTD, PIN0);
    }
  else
    {
      iseed = iseed << 1;      
      clear_bit(PORTD, PIN0);
    }
}
