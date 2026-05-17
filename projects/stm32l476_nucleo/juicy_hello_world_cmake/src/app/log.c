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

/*********************
 *      INCLUDES
 *********************/
#include "log.h"
//
#include "main.h"
#include "usart.h"

#include <string.h>

/*********************
 *      DEFINES
 *********************/


/**********************
 *      TYPEDEFS
 **********************/

/**********************
 *  STATIC PROTOTYPES
 **********************/

/**********************
 *  STATIC VARIABLES
 **********************/

/**********************
 *      MACROS
 **********************/

/**********************
 *  GLOBAL VARIABLES
 **********************/
LogData __log__;

/**********************
 *   GLOBAL FUNCTIONS
 **********************/
void log_sting(const char *fmt)
{
    HAL_UART_Transmit(&huart2, (const uint8_t *)fmt, strlen(fmt), 1000);
}

void log_buffer(const uint8_t *buf, size_t len)
{
    HAL_UART_Transmit(&huart2, buf, len, 1000);
}

/**********************
 *   STATIC FUNCTIONS
 **********************/

/**********************
 *   ERROR ASSERT
 **********************/
