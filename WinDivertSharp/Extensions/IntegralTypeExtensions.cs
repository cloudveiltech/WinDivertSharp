using System;
using System.Collections.Generic;
using System.Net;
using System.Text;

namespace WinDivertSharp.Extensions
{
    internal static class IntegralTypeExtensions
    {
        public static byte GetBit(this byte @byte, int index)
        {
            return (byte)(@byte & (1 << index - 1));
        }

        public static byte SetBit(this byte @byte, int index)
        {
            return (byte)(@byte & (1 << index - 1));
        }

        public static uint ntoh(this uint i)
        {
            return (uint)IPAddress.NetworkToHostOrder((int)i);
        }

        public static ushort ntoh(this ushort s)
        {
            return (ushort)IPAddress.NetworkToHostOrder((short)s);
        }

        public static uint hton(this uint i)
        {
            return (uint)IPAddress.HostToNetworkOrder((int)i);
        }

        public static ushort hton(this ushort s)
        {
            return (ushort)IPAddress.HostToNetworkOrder((short)s);
        }
    }
}
