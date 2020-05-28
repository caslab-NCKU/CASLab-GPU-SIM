#ifndef __H_OCKL__
#define __H_OCKL__

#pragma OPENCL EXTENSION cl_khr_fp16 : enable
extern __attribute__((const)) size_t __ockl_get_global_id(uint);
extern __attribute__((const)) size_t __ockl_get_local_id(uint);
extern __attribute__((const)) size_t __ockl_get_group_id(uint);
extern __attribute__((const)) size_t __ockl_get_global_size(uint);
extern __attribute__((const)) size_t __ockl_get_local_size(uint);
extern __attribute__((const)) size_t __ockl_get_num_groups(uint);
extern __attribute__((const)) uint __ockl_get_work_dim(void);

#endif
