#ifndef PROJECT_HEAT_PCSHELL_MT_H
#define PROJECT_HEAT_PCSHELL_MT_H
#include <petscksp.h>
#include "StrumpackSparseSolver.h"

/* The application owns the context until after KSPDestroy(). */
typedef struct {
  STRUMPACK_SparseSolver solver;
  PetscInt grid, setups, applies, destroys;
  PetscBool initialized;
} HeatMTContext;

PetscErrorCode HeatMTAttach(PC, PetscInt, HeatMTContext *);
#endif
