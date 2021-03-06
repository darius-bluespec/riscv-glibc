/* Copyright (C) 2005 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

#ifdef __riscv_atomic

#include <errno.h>

int pthread_spin_trylock(pthread_spinlock_t* lock)
{
  int tmp1, tmp2;

  asm volatile ("\n\
    lw           %0, 0(%2)\n\
    li           %1, %3\n\
    bnez         %0, 1f\n\
    amoswap.w.aq %0, %1, 0(%2)\n\
  1:"
    : "=&r"(tmp1), "=&r"(tmp2) : "r"(lock), "i"(EBUSY)
  );

  return tmp1;
}

#else  /* __riscv_atomic */

#include <sysdeps/../nptl/pthread_spin_trylock.c>

#endif  /* !__riscv_atomic */
