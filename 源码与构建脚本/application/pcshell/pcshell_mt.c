#include "pcshell_mt.h"
#include <limits.h>

_Static_assert(sizeof(PetscInt) == sizeof(int), "STRUMPACK_DOUBLE uses int32 indices");
_Static_assert(sizeof(PetscScalar) == sizeof(double), "Adapter requires real double");
#if defined(PETSC_USE_COMPLEX) || defined(PETSC_USE_64BIT_INDICES)
#error "This adapter supports real double / 32-bit indices only"
#endif

static PetscErrorCode HeatMTSetUp(PC pc)
{
  HeatMTContext *ctx;
  Mat A;
  const PetscInt *rowptr, *colind;
  const PetscScalar *values;
  PetscInt n, cols, rows;
  PetscBool done, seqaij;
  STRUMPACK_RETURN_CODE rc;

  PetscFunctionBeginUser;
  PetscCall(PCShellGetContext(pc, &ctx));
  PetscCall(PCGetOperators(pc, &A, NULL));
  PetscCall(PetscObjectTypeCompare((PetscObject)A, MATSEQAIJ, &seqaij));
  PetscCheck(seqaij, PETSC_COMM_SELF, PETSC_ERR_SUP, "Adapter requires sequential AIJ");
  PetscCall(MatGetSize(A, &n, &cols));
  PetscCheck(n == cols && n == ctx->grid * ctx->grid && n <= INT_MAX,
             PETSC_COMM_SELF, PETSC_ERR_ARG_SIZ, "Regular square-grid matrix required");
  if (ctx->initialized) STRUMPACK_destroy(&ctx->solver);
  ctx->initialized = PETSC_FALSE;
  STRUMPACK_init_mt(&ctx->solver, STRUMPACK_DOUBLE, STRUMPACK_MT, 0, NULL, 0);
  ctx->initialized = PETSC_TRUE;
  STRUMPACK_set_matching(ctx->solver, STRUMPACK_MATCHING_NONE);
  STRUMPACK_set_reordering_method(ctx->solver, STRUMPACK_GEOMETRIC);
  STRUMPACK_set_compression(ctx->solver, STRUMPACK_NONE);
  STRUMPACK_set_Krylov_solver(ctx->solver, STRUMPACK_DIRECT);
  PetscCall(MatGetRowIJ(A, 0, PETSC_FALSE, PETSC_FALSE, &rows, &rowptr, &colind, &done));
  PetscCheck(done && rows == n, PETSC_COMM_SELF, PETSC_ERR_SUP, "CSR view unavailable");
  PetscCall(MatSeqAIJGetArrayRead(A, &values));
  /* set_csr_matrix() copies all three arrays. PETSc retains their ownership. */
  STRUMPACK_set_csr_matrix(ctx->solver, &n, rowptr, colind, values, 1);
  PetscCall(MatSeqAIJRestoreArrayRead(A, &values));
  PetscCall(MatRestoreRowIJ(A, 0, PETSC_FALSE, PETSC_FALSE, &rows, &rowptr, &colind, &done));
  PetscCheck(done, PETSC_COMM_SELF, PETSC_ERR_LIB, "CSR restore failed");
  rc = STRUMPACK_reorder_regular(ctx->solver, ctx->grid, ctx->grid, 1, 1, 1);
  PetscCheck(rc == STRUMPACK_SUCCESS, PETSC_COMM_SELF, PETSC_ERR_LIB, "STRUMPACK reorder failed: %d", (int)rc);
  rc = STRUMPACK_factor(ctx->solver);
  PetscCheck(rc == STRUMPACK_SUCCESS, PETSC_COMM_SELF, PETSC_ERR_LIB, "STRUMPACK factor failed: %d", (int)rc);
  ctx->setups++;
  PetscFunctionReturn(PETSC_SUCCESS);
}

static PetscErrorCode HeatMTApply(PC pc, Vec b, Vec x)
{
  HeatMTContext *ctx;
  const PetscScalar *rhs;
  PetscScalar *solution;
  STRUMPACK_RETURN_CODE rc;

  PetscFunctionBeginUser;
  PetscCall(PCShellGetContext(pc, &ctx));
  PetscCheck(ctx->initialized && b != x, PETSC_COMM_SELF, PETSC_ERR_ARG_WRONGSTATE, "Separate vectors and a factored solver required");
  PetscCall(VecGetArrayRead(b, &rhs));
  PetscCall(VecGetArray(x, &solution));
  rc = STRUMPACK_solve(ctx->solver, rhs, solution, 0);
  PetscCall(VecRestoreArray(x, &solution));
  PetscCall(VecRestoreArrayRead(b, &rhs));
  PetscCheck(rc == STRUMPACK_SUCCESS, PETSC_COMM_SELF, PETSC_ERR_LIB, "STRUMPACK solve failed: %d", (int)rc);
  ctx->applies++;
  PetscFunctionReturn(PETSC_SUCCESS);
}

static PetscErrorCode HeatMTDestroy(PC pc)
{
  HeatMTContext *ctx;

  PetscFunctionBeginUser;
  PetscCall(PCShellGetContext(pc, &ctx));
  if (ctx->initialized) STRUMPACK_destroy(&ctx->solver);
  ctx->initialized = PETSC_FALSE;
  ctx->destroys++;
  PetscFunctionReturn(PETSC_SUCCESS);
}

PetscErrorCode HeatMTAttach(PC pc, PetscInt grid, HeatMTContext *ctx)
{
  PetscFunctionBeginUser;
  ctx->grid = grid;
  PetscCall(PCSetType(pc, PCSHELL));
  PetscCall(PCShellSetName(pc, "STRUMPACK MT regular-grid direct solve"));
  PetscCall(PCShellSetContext(pc, ctx));
  PetscCall(PCShellSetSetUp(pc, HeatMTSetUp));
  PetscCall(PCShellSetApply(pc, HeatMTApply));
  PetscCall(PCShellSetDestroy(pc, HeatMTDestroy));
  PetscFunctionReturn(PETSC_SUCCESS);
}
