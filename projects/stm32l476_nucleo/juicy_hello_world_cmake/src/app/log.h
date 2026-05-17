
/** @copyright Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 * associated documentation files (the "Software"), to deal in the Software without restriction, including without
 * limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
 * Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
 * Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * @author    Sazerac4 (lm-embeddedsystems@laposte.net)
 * @date      08-2025
 */
/**
 *  @file log.h
 *  @brief
 *  @pre
 *  @details
 */

#ifndef __LOG_H__
#define __LOG_H__

#ifdef __cplusplus
extern "C"
{
#endif

/*********************
 *      INCLUDES
 *********************/
#include "cmsis_compiler.h"

#include <stdio.h>

/*********************
 *      DEFINES
 *********************/
#define CFG_LOG_MAX_BUFFER (512)
#define CFG_LOG_ENDLINE    "\r\n"
//

/**********************
 *     TYPEDEFS
 **********************/
typedef struct
{
    size_t len;
    __ALIGNED(4) char output[CFG_LOG_MAX_BUFFER];
} LogData;

/**********************
 *  GLOBAL MACROS
 **********************/
// NOLINTBEGIN(readability-identifier-naming)

// utility
#define _boost_join(X, Y)   __boost_join(X, Y)
#define __boost_join(X, Y)  ___boost_join(X, Y)
#define ___boost_join(X, Y) X##Y

#define __num_args(...)                                                         __narg_index_(__VA_ARGS__, __r_seq_n())
#define __narg_index_(...)                                                      __arg_n(__VA_ARGS__)
#define __arg_n(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, N, ...) N
#define __r_seq_n()                                                             3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 1
#define __vfunc(func, ...) _boost_join(func, __num_args(__VA_ARGS__))(__VA_ARGS__)

//
#define __LOG_GENERIC_1()         log_sting(CFG_LOG_ENDLINE)
#define __LOG_GENERIC_2(str)      log_sting(str CFG_LOG_ENDLINE)
#define __LOG_GENERIC_3(fmt, ...) log_varg(fmt CFG_LOG_ENDLINE, __VA_ARGS__)
//
#define __Log(...) __vfunc(__LOG_GENERIC_, __VA_ARGS__)

// Public API
#define LOG(...) __Log(__VA_ARGS__)


/**********************
 *  GLOBAL VARIABLES
 **********************/
extern LogData __log__;

/**********************
 *  GLOBAL PROTOTYPES
 **********************/
void log_sting(const char *fmt);
void log_buffer(const uint8_t *buf, size_t len);

#define log_varg(fmt, ...)                                                                        \
    do                                                                                            \
    {                                                                                             \
        __log__.len = (size_t)snprintf(__log__.output, sizeof(__log__.output), fmt, __VA_ARGS__); \
        log_buffer((const uint8_t *)__log__.output, __log__.len);                                 \
    } while (0);


/**********************
 *   ERROR ASSERT
 **********************/

// NOLINTEND(readability-identifier-naming)

#ifdef __cplusplus
}
#endif

#endif /* __LOG_H__ */
