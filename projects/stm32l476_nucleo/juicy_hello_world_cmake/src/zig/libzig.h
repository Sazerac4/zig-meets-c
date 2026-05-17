
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
 *  @file libzig.h
 *  @brief
 *  @pre
 *  @details
 */

#ifndef __LIB_ZIG_H__
#define __LIB_ZIG_H__

#ifdef __cplusplus
extern "C"
{
#endif

/*********************
 *      INCLUDES
 *********************/
#include <stddef.h>
#include <stdint.h>

/*********************
 *      DEFINES
 *********************/

/**********************
 *     TYPEDEFS
 **********************/

/**********************
 *  GLOBAL MACROS
 **********************/

/**********************
 *  GLOBAL VARIABLES
 **********************/
extern const uint32_t hash_project_name;

/**********************
 *  GLOBAL PROTOTYPES
 **********************/
int b58_encode(const uint8_t *input, size_t inlen, uint8_t *buffer, size_t outlen);
int b58_decode(const uint8_t *input, size_t inlen, uint8_t *buffer, size_t outlen);
uint64_t cityhash64(const uint8_t *input, size_t len);
const char *zig_error_to_string(int error);

/**********************
 *   ERROR ASSERT
 **********************/

#ifdef __cplusplus
}
#endif

#endif /* __LIB_ZIG_H__ */
