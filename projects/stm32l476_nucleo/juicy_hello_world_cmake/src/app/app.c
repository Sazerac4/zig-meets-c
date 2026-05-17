
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
#include "app.h"

#include "gpio.h"
#include "libzig.h"
#include "log.h"
#include "main.h"
#include "usart.h"

#include <inttypes.h>

/*********************
 *      DEFINES
 *********************/
#define B58_SIZE (20)

/**********************
 *      TYPEDEFS
 **********************/
typedef __PACKED_UNION HwUid
{
    struct
    {
        uint32_t uid_1;
        uint32_t uid_2;
        uint32_t uid_3;
    };
    uint32_t a_uid[3];
}
HwUid;


/**********************
 *  STATIC PROTOTYPES
 **********************/
static HwUid *get_uid(void);

/**********************
 *  STATIC VARIABLES
 **********************/

/**********************
 *      MACROS
 **********************/
#define COUNT_OF(X) (unsigned int)(sizeof(X) / sizeof((X)[0]))

/**********************
 *  GLOBAL VARIABLES
 **********************/

/**********************
 *   GLOBAL FUNCTIONS
 **********************/
void app_entrypoint(void)
{
    HwUid *huid = get_uid();

    // Print informations then loop blink
    LOG();
    LOG();
    LOG("Project:      %s", PROJECT_NAME);
    LOG("Project Hash: %08" PRIx32, hash_project_name);
    LOG("Commit:       %08x", PROJECT_COMMIT);
    LOG("Git:          %s", PROJECT_GIT_DESCRIBE);
    LOG("Compiler:     %s", __VERSION__);
    LOG("Build type:   %s", PROJECT_BUILD_TYPE);
    LOG("S.N (96b):    %08" PRIX32 "%08" PRIX32 "%08" PRIX32, huid->uid_1, huid->uid_2, huid->uid_3);

    // We use a hash to create a smaller serial number one 96 bits to 64 bits
    uint64_t serial_number_hash = cityhash64((const uint8_t *)huid->a_uid, sizeof(huid->a_uid));
    // We will store a base58 unique ID
    uint8_t serial_number_base58[B58_SIZE];

    int error = b58_encode((const uint8_t *)&serial_number_hash,
                           sizeof(serial_number_hash),
                           serial_number_base58,
                           sizeof(serial_number_base58));
    if (error < 0)
    {
        LOG("Error when encoding: %s (%d)", zig_error_to_string(error), error);
    }
    else
    {
        LOG("S.N (64b):    %08" PRIX32 "%08" PRIX32,
            (uint32_t)((serial_number_hash >> 32) & UINT32_MAX),
            (uint32_t)(serial_number_hash & UINT32_MAX));
        LOG("S.N (b58):    \"%s\"", serial_number_base58);
    }
    LOG();
    LOG("Hello, World!");
    LOG();

    // Blink time !
    while (1)
    {
        HAL_GPIO_WritePin(LD2_GPIO_Port, LD2_Pin, GPIO_PIN_RESET);
        HAL_Delay(200); // NOLINT(readability-magic-numbers)
        HAL_GPIO_WritePin(LD2_GPIO_Port, LD2_Pin, GPIO_PIN_SET);
        HAL_Delay(500); // NOLINT(readability-magic-numbers)
    }
}

/**********************
 *   STATIC FUNCTIONS
 **********************/
static HwUid *get_uid(void)
{
    // UID[95:64]: LOT_NUM[55:24] – Lot number (ASCII encoded)
    // UID[39:32]: WAF_NUM[7:0] – Wafer number (8-bit unsigned number)
    // UID[63:40]: LOT_NUM[23:0] – Lot number (ASCII encoded)
    // UID[31:0]: X and Y coordinates on the wafer
    return (HwUid *)UID_BASE;
}


/**********************
 *   ERROR ASSERT
 **********************/
