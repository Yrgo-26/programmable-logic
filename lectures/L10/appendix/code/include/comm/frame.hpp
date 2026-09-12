/**
 * @file Frame implementation.
 */
#pragma once

#include <cstddef>
#include <cstdint>

#include "comm/def.hpp"

namespace comm
{
/**
 * @brief Frame structure.
 */
struct Frame
{
    //! @todo Declare the member variables here (the framing exercises, Part II, step 3).
    //!       Value-initialize each one with braces: numeric members to {},
    //!       and the frame type to {FrameType::Unknown}.

    /**
     * @brief Serialize this frame into a byte buffer.
     *
     * @param[out] buf Buffer to serialize into.
     * @param[in] bufLen Length of the buffer, in bytes.
     *
     * @return The number of serialized bytes, or 0 on failure.
     */
    [[nodiscard]] std::size_t serialize(std::uint8_t* buf, std::size_t bufLen) const noexcept;

    /**
     * @brief Deserialize a frame from a byte buffer into this instance.
     *
     * @param[in] buf Buffer to deserialize from.
     * @param[in] bufLen Length of the buffer, in bytes.
     *
     * @return True on success, false on failure.
     */
    [[nodiscard]] bool deserialize(const std::uint8_t* buf, std::size_t bufLen) noexcept;
};
} // namespace comm
