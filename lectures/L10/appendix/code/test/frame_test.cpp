/**
 * @file Unit tests for comm::Frame.
 *
 *       The expected byte sequences are the frames worked out by hand in the framing
 *       introduction and in the framing exercises, Part I, so a failure here can be compared
 *       directly against your own paper calculation.
 */
#include <cstddef>
#include <cstdint>
#include <type_traits>

#include "comm/def.hpp"
#include "comm/frame.hpp"
#include "qacademy/test/test.hpp"

//! @todo Enable by adding -DL01 to CXX_FLAGS in the Makefile (the framing exercises, Part II, step 6).
#ifdef L01

using namespace comm;

namespace
{
/** The PING frame worked out in the framing introduction: 0x01 -> 0x02, seq 0x0020, no payload. */
constexpr std::uint8_t PingBytes[]{0xA5U, 0xF7U, 0x00U, 0x00U, 0x02U,
                                   0x01U, 0x00U, 0x20U, 0x01U, 0xBFU};

/** The StatusReq frame from Part I(a): 0x17 -> 0x25, seq 0x7F05, no payload. */
constexpr std::uint8_t StatusReqBytes[]{0xA5U, 0xF7U, 0x00U, 0x02U, 0x25U,
                                        0x17U, 0x7FU, 0x05U, 0x02U, 0x5EU};

/** The StatusResp frame from Part I(b): 0x25 -> 0x17, seq 0x7F05, payload 0x3201. */
constexpr std::uint8_t StatusRespBytes[]{0xA5U, 0xF7U, 0x02U, 0x03U, 0x17U, 0x25U,
                                         0x7FU, 0x05U, 0x32U, 0x01U, 0x02U, 0x94U};

// -----------------------------------------------------------------------------
template<typename T>
[[nodiscard]] constexpr bool match(const T value1, const T value2) noexcept
{
    static_assert(std::is_arithmetic<T>::value || std::is_enum<T>::value,
                  "T must be arithmetic or of enum type!");
    if constexpr (std::is_enum<T>::value)
    {
        return static_cast<int>(value1) == static_cast<int>(value2);
    }
    else { return value1 == value2; }
}

// -----------------------------------------------------------------------------
constexpr void writeU16(std::uint8_t* buf, const std::size_t offset,
                        const std::uint16_t val) noexcept
{
    constexpr std::size_t shift{8U};
    buf[offset]      = static_cast<std::uint8_t>(val >> shift);
    buf[offset + 1U] = static_cast<std::uint8_t>(val);
}

// -----------------------------------------------------------------------------
[[nodiscard]] constexpr std::uint16_t readU16(const std::uint8_t* buf,
                                              const std::size_t offset) noexcept
{
    constexpr std::size_t shift{8U};
    return (static_cast<std::uint16_t>(buf[offset]) << shift) |
           (static_cast<std::uint16_t>(buf[offset + 1U]));
}

// -----------------------------------------------------------------------------
[[nodiscard]] Frame makeFrame(const FrameType type, const std::uint8_t dst, const std::uint8_t src,
                              const std::uint16_t seq, const std::uint8_t* data = nullptr,
                              const std::uint8_t len = 0U) noexcept
{
    Frame frame{};
    frame.type = type;
    frame.dst  = dst;
    frame.src  = src;
    frame.seq  = seq;
    frame.len  = len;

    for (std::size_t i{}; i < len; ++i)
    {
        frame.data[i] = data[i];
    }
    return frame;
}

// -----------------------------------------------------------------------------
void expectBytes(const std::uint8_t* actual, const std::uint8_t* expected, const std::size_t len)
{
    for (std::size_t i{}; i < len; ++i)
    {
        EXPECT_EQ(actual[i], expected[i]);
    }
}
} // namespace

/**
 * @brief Serialize a PING frame.
 *
 *        Serialize the PING frame worked out in the framing introduction, expect the exact bytes
 *        written there and a length of ten.
 */
TEST(Frame, SerializePing)
{
    constexpr std::uint8_t dst{0x02U};
    constexpr std::uint8_t src{0x01U};
    constexpr std::uint16_t seq{0x0020U};
    std::uint8_t buf[MaxFrameLen]{};

    const auto frame = makeFrame(FrameType::Ping, dst, src, seq);
    EXPECT_EQ(frame.serialize(buf, sizeof(buf)), sizeof(PingBytes));
    expectBytes(buf, PingBytes, sizeof(PingBytes));
}

/**
 * @brief Serialize a StatusReq frame.
 *
 *        Serialize the frame built by hand in Part I(a), expect the exact bytes from that
 *        calculation.
 */
TEST(Frame, SerializeStatusReq)
{
    constexpr std::uint8_t dst{0x25U};
    constexpr std::uint8_t src{0x17U};
    constexpr std::uint16_t seq{0x7F05U};
    std::uint8_t buf[MaxFrameLen]{};

    const auto frame = makeFrame(FrameType::StatusReq, dst, src, seq);
    EXPECT_EQ(frame.serialize(buf, sizeof(buf)), sizeof(StatusReqBytes));
    expectBytes(buf, StatusReqBytes, sizeof(StatusReqBytes));
}

/**
 * @brief Serialize a StatusResp frame carrying a payload.
 *
 *        Serialize the frame built by hand in Part I(b), expect the exact bytes from that
 *        calculation, payload included.
 */
TEST(Frame, SerializeStatusResp)
{
    constexpr std::uint8_t dst{0x17U};
    constexpr std::uint8_t src{0x25U};
    constexpr std::uint16_t seq{0x7F05U};
    constexpr std::uint8_t data[]{0x32U, 0x01U};
    constexpr std::uint8_t len{static_cast<std::uint8_t>(sizeof(data))};
    std::uint8_t buf[MaxFrameLen]{};

    const auto frame = makeFrame(FrameType::StatusResp, dst, src, seq, data, len);
    EXPECT_EQ(frame.serialize(buf, sizeof(buf)), sizeof(StatusRespBytes));
    expectBytes(buf, StatusRespBytes, sizeof(StatusRespBytes));
}

/**
 * @brief Serialize into a null buffer.
 *
 *        Serialize a valid frame into a null buffer, expect 0 and no write.
 */
TEST(Frame, SerializeRejectsNullBuffer)
{
    constexpr std::uint8_t dst{0x02U};
    constexpr std::uint8_t src{0x01U};
    constexpr std::uint16_t seq{0x0020U};
    constexpr std::size_t opFailure{0U};

    const auto frame = makeFrame(FrameType::Ping, dst, src, seq);
    EXPECT_EQ(frame.serialize(nullptr, MaxFrameLen), opFailure);
}

/**
 * @brief Serialize into an undersized buffer.
 *
 *        Serialize a valid frame into a buffer smaller than the minimum frame, expect 0.
 */
TEST(Frame, SerializeRejectsTooSmallBuffer)
{
    constexpr std::uint8_t dst{0x02U};
    constexpr std::uint8_t src{0x01U};
    constexpr std::uint16_t seq{0x0020U};
    constexpr std::size_t opFailure{0U};
    std::uint8_t buf[MinFrameLen - 1U]{};

    const auto frame = makeFrame(FrameType::Ping, dst, src, seq);
    EXPECT_EQ(frame.serialize(buf, sizeof(buf)), opFailure);
}

/**
 * @brief Deserialize a frame without a payload.
 *
 *        Deserialize the Part I(a) bytes, expect success and every header field recovered.
 */
TEST(Frame, DeserializeRecoversHeaderFields)
{
    constexpr std::uint16_t seq{readU16(StatusReqBytes, FrameOffset::Seq)};
    Frame frame{};

    EXPECT_TRUE(frame.deserialize(StatusReqBytes, sizeof(StatusReqBytes)));
    EXPECT_TRUE(match(frame.type, FrameType::StatusReq));
    EXPECT_TRUE(match(frame.dst, StatusReqBytes[FrameOffset::Dst]));
    EXPECT_TRUE(match(frame.src, StatusReqBytes[FrameOffset::Src]));
    EXPECT_TRUE(match(frame.seq, seq));
    EXPECT_TRUE(match(frame.len, StatusReqBytes[FrameOffset::Len]));
}

/**
 * @brief Deserialize a frame carrying a payload.
 *
 *        Deserialize the Part I(b) bytes, expect success, a length of two, and both payload
 *        bytes recovered in order.
 */
TEST(Frame, DeserializeRecoversPayload)
{
    Frame frame{};
    EXPECT_TRUE(frame.deserialize(StatusRespBytes, sizeof(StatusRespBytes)));

    EXPECT_TRUE(match(frame.len, StatusRespBytes[FrameOffset::Len]));

    for (std::uint8_t i{}; i < frame.len; ++i)
    {
        EXPECT_TRUE(match(frame.data[i], StatusRespBytes[FrameOffset::Data + i]));
    }
}

/**
 * @brief Serialize a frame and deserialize the result.
 *
 *        Round-trip a frame with a four-byte payload, expect the deserialized frame to match the
 *        original field for field.
 */
TEST(Frame, RoundTripPreservesEveryField)
{
    constexpr std::uint8_t dst{0x42U};
    constexpr std::uint8_t src{0x13U};
    constexpr std::uint16_t seq{0xBEEFU};
    constexpr std::uint8_t data[]{0xDEU, 0xADU, 0xBEU, 0xEFU};
    constexpr std::size_t len{sizeof(data) / sizeof(data[0U])};

    const auto sent = makeFrame(FrameType::Pong, dst, src, seq, data, len);
    std::uint8_t buf[MaxFrameLen]{};

    const auto sentBytes = sent.serialize(buf, sizeof(buf));
    EXPECT_NE(sentBytes, 0U);

    Frame received{};
    EXPECT_TRUE(received.deserialize(buf, sentBytes));
    EXPECT_TRUE(match(received.type, sent.type));
    EXPECT_TRUE(match(received.dst, sent.dst));
    EXPECT_TRUE(match(received.src, sent.src));
    EXPECT_TRUE(match(received.seq, sent.seq));
    EXPECT_TRUE(match(received.len, sent.len));

    for (std::size_t i{}; i < len; ++i)
    {
        EXPECT_TRUE(match(received.data[i], data[i]));
    }
}

/**
 * @brief Deserialize from a null buffer.
 *
 *        Deserialize from a null buffer, expect failure.
 */
TEST(Frame, DeserializeRejectsNullBuffer)
{
    Frame frame{};
    EXPECT_FALSE(frame.deserialize(nullptr, MinFrameLen));
}

/**
 * @brief Deserialize from an undersized buffer.
 *
 *        Deserialize from a buffer shorter than the minimum frame, expect failure.
 */
TEST(Frame, DeserializeRejectsShortBuffer)
{
    constexpr std::size_t frameLen{MinFrameLen - 1U};
    Frame frame{};
    EXPECT_FALSE(frame.deserialize(PingBytes, frameLen));
}

/**
 * @brief Deserialize a frame with a corrupted sync word.
 *
 *        Corrupt the first SOF byte, then deserialize, expect failure.
 */
TEST(Frame, DeserializeRejectsBadSof)
{
    std::uint8_t buf[sizeof(PingBytes)]{};

    for (std::size_t i{}; i < sizeof(buf); ++i)
    {
        buf[i] = PingBytes[i];
    }
    buf[FrameOffset::Sof]++;

    Frame frame{};
    EXPECT_FALSE(frame.deserialize(buf, sizeof(buf)));
}

/**
 * @brief Deserialize a frame with a corrupted checksum.
 *
 *        Corrupt the low checksum byte, then deserialize, expect failure.
 */
TEST(Frame, DeserializeRejectsBadChecksum)
{
    constexpr std::size_t bufLen{sizeof(PingBytes)};
    constexpr std::size_t chkLowOffset{bufLen - 1U};
    constexpr std::uint8_t chkMask{0xFFU};
    std::uint8_t buf[bufLen]{};

    for (std::size_t i{}; i < sizeof(buf); ++i)
    {
        buf[i] = PingBytes[i];
    }
    buf[chkLowOffset] ^= chkMask;

    Frame frame{};
    EXPECT_FALSE(frame.deserialize(buf, sizeof(buf)));
}

/**
 * @brief Deserialize a frame with an out-of-range type.
 *
 *        Set the type byte to Unknown and repair the checksum so the type is the only fault,
 *        then deserialize, expect failure.
 */
TEST(Frame, DeserializeRejectsInvalidType)
{
    constexpr std::size_t bufLen{sizeof(PingBytes)};
    std::uint8_t buf[bufLen]{};

    for (std::size_t i{}; i < sizeof(buf); ++i)
    {
        buf[i] = PingBytes[i];
    }

    // Set the type to Unknown, the first invalid value, and repair the checksum so that the
    // type check is the only reason this frame can be rejected.
    constexpr std::uint8_t bad{static_cast<std::uint8_t>(FrameType::Unknown)};
    const auto delta       = static_cast<std::uint8_t>(bad - buf[FrameOffset::Type]);
    buf[FrameOffset::Type] = bad;

    constexpr std::size_t chkOffset{FrameOffset::chk(PingBytes[FrameOffset::Len])};
    const auto old   = readU16(buf, chkOffset);
    const auto fixed = static_cast<std::uint16_t>(old + delta);
    writeU16(buf, chkOffset, fixed);

    Frame frame{};
    EXPECT_FALSE(frame.deserialize(buf, sizeof(buf)));
}

/**
 * @brief Deserialize a frame whose payload is cut short.
 *
 *        Deserialize a frame whose LEN claims more payload than the buffer holds, expect
 *        failure.
 */
TEST(Frame, DeserializeRejectsTruncatedPayload)
{
    constexpr std::size_t bufLen{sizeof(StatusRespBytes) - 2U};
    Frame frame{};
    EXPECT_FALSE(frame.deserialize(StatusRespBytes, bufLen));
}

/**
 * @brief Deserialize into a frame that already holds data.
 *
 *        Deserialize a corrupted buffer into a populated frame, expect failure and every field
 *        left exactly as it was.
 *
 *        The framing introduction stresses that every field is validated before any of it is
 *        stored. A deserialize() that copies fields as it parses them corrupts the frame on the
 *        way to returning false, and this is the test that catches it.
 */
TEST(Frame, DeserializeLeavesFrameUntouchedOnFailure)
{
    constexpr std::uint8_t dst{0x11U};
    constexpr std::uint8_t src{0x22U};
    constexpr std::uint16_t seq{0x3344U};
    constexpr std::uint8_t len{0U};

    constexpr std::size_t bufLen{sizeof(StatusRespBytes)};
    constexpr std::size_t chkLowOffset{bufLen - 1U};
    constexpr std::uint8_t chkMask{0xFFU};
    std::uint8_t buf[bufLen]{};

    for (std::size_t i{}; i < sizeof(buf); ++i)
    {
        buf[i] = StatusRespBytes[i];
    }
    buf[chkLowOffset] ^= chkMask;

    Frame frame{makeFrame(FrameType::Ping, dst, src, seq)};
    EXPECT_FALSE(frame.deserialize(buf, sizeof(buf)));

    EXPECT_TRUE(match(frame.type, FrameType::Ping));
    EXPECT_TRUE(match(frame.dst, dst));
    EXPECT_TRUE(match(frame.src, src));
    EXPECT_TRUE(match(frame.seq, seq));
    EXPECT_TRUE(match(frame.len, len));
}

#endif /** L01 */
