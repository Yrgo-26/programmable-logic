/**
 * @file Frame definitions.
 */
#pragma once

#include <cstddef>
#include <cstdint>

namespace comm
{
/**
 * @brief Enumeration of frame types.
 *
 * @todo Implement these enumerators (the framing exercises, Part II, step 2).
 */
enum class FrameType : std::uint8_t
{
    ///< Ping frame.
    ///< Pong frame.
    ///< Status request frame.
    ///< Status response frame.
    ///< Unknown frame (must be last - the first invalid value).
};

/**
 * @brief Byte offsets of each field within a serialized frame.
 */
struct FrameOffset
{
    static constexpr std::size_t Sof{0U};  ///< Start-of-frame offset.
    static constexpr std::size_t Len{2U};  ///< Payload length offset.
    static constexpr std::size_t Type{3U}; ///< Frame type offset.
    static constexpr std::size_t Dst{4U};  ///< Destination address offset.
    static constexpr std::size_t Src{5U};  ///< Source address offset.
    static constexpr std::size_t Seq{6U};  ///< Sequence number offset.
    static constexpr std::size_t Data{8U}; ///< Data (payload) offset.

    /**
     * @brief Get the checksum offset for a given payload length.
     *
     * @param[in] dataLen Data (payload) length, in bytes.
     *
     * @return The checksum offset (the first byte after the DATA field).
     */
    static constexpr std::size_t chk(const std::size_t dataLen) noexcept { return Data + dataLen; }
};

/** Header length (SOF..SEQ), in bytes. */
constexpr std::size_t HeaderLen{8U};

/** Footer length (CHK), in bytes. */
constexpr std::size_t FooterLen{2U};

/** Maximum data (payload) length, in bytes. */
constexpr std::size_t MaxDataLen{10U};

/** Minimum frame length (header + footer, no payload), in bytes. */
constexpr std::size_t MinFrameLen{HeaderLen + FooterLen};

/** Maximum frame length (header + max payload + footer), in bytes. */
constexpr std::size_t MaxFrameLen{MinFrameLen + MaxDataLen};

/** Start-of-frame sync word. */
constexpr std::uint16_t Sof{0xA5F7U};

} // namespace comm
