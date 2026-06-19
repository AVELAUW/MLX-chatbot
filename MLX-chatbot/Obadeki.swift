//
//  Obadeki.swift
//  MLX-chatbot
//

import Foundation
import CryptoKit

struct Obadeki {

    static func containsOffensiveContent(_ text: String) -> Bool {
        let lowered = text.lowercased()

        // Check individual words against hashed list
        let words = lowered.components(separatedBy: .alphanumerics.inverted).filter { !$0.isEmpty }
        for word in words where blockedWordHashes.contains(md5(word)) {
            return true
        }

        // Check multi-word phrases (stored encoded)
        for phrase in decodedPhrases where lowered.contains(phrase) {
            return true
        }

        return false
    }

    // MARK: - MD5 helper (consistent across devices, unlike .hashValue)

    private static func md5(_ string: String) -> UInt64 {
        let digest = Insecure.MD5.hash(data: Data(string.utf8))
        let b = Array(digest)
        return UInt64(b[0]) << 56 | UInt64(b[1]) << 48 | UInt64(b[2]) << 40 | UInt64(b[3]) << 32
             | UInt64(b[4]) << 24 | UInt64(b[5]) << 16 | UInt64(b[6]) <<  8 | UInt64(b[7])
    }

    // MARK: - Individual words stored as MD5 hashes (no plain text)

    private static let blockedWordHashes: Set<UInt64> = [
        0x99754106633f94d3, 0x8561b0da13f41d73, 0x823299e0dbcad6c1, 0xaac0a9daa4185875,
        0x788da20fc6ffb6e2, 0x8d70e0d1acb06b46, 0x2f8d4aea377fd1fe, 0x1223b8c30a347321,
        0xf8d1e57447a2556b, 0xd2aefeac9dc661bc, 0x48106a12a0004866, 0xecb27bf66c32a671,
        0xabb6449b4c7eaed1, 0x964d72e72d053d50, 0x0b9a54438fba2dc0, 0xc25a68128b55eab8,
        0xb529d8871187ecc7, 0x02567cc5953bec53, 0x316928e0d260556e, 0xbbf4cf5c9c38f3b3,
        0xd7dbc71aabaa1e13, 0x4dd77ecaf88620f5, 0x769411df5d33ac35, 0xe903d4d92fb20751,
        0xe42b93ccb6b3bd31, 0xb0d7afc8ffd4ec41, 0xb52b073595ccb35e, 0xfea321ba42e9f3c5,
        0x7f55a0ed8b021080, 0xe62a73b624eabdc6, 0x9268d0b2d1767059, 0xacc6f2779b808637,
        0xd15b0ff178b085c8, 0xfe325cf304ee9155, 0x3e12ec4d994fefe4, 0xa453620c9c6fe7a6,
        0x32e09232d75641f6, 0x2ece57080d954570, 0xb11aa5b409849b75, 0x5a05a7e4e2971194,
        0x2da1ab427df46b3c, 0xafec462d47319367, 0x693e810ff27604e6, 0xc35312fb3a7e05b7,
        0xbf4b3ba0692b4378, 0x9271d6eecedd55fc, 0xf5ab462e064d758a, 0x2ea76074f435b632,
        0x848908bf8a95da5c, 0x066fc7b468bbf620, 0xb1860783a249a024, 0x37eee4e91ccb5208,
        0x2f63b25723572a05, 0x81c8eb975df1d58c, 0x8eec5df1378a629d, 0x2b5a15d9f8f1dcf9,
        0xa37620bc5641c271, 0xc592eff5625d551b, 0xcb205edee16b2436, 0x7990139b8697d215,
        0x1d123b3c5603b87f, 0xbf1f178a61616e1a, 0xef9c22bc74f20481, 0x70d75a49ff844a98,
    ]

    // MARK: - Multi-word phrases stored base64-encoded (substring matching requires plain text at runtime)

    private static let decodedPhrases: [String] = {
        let encoded = "a2lsbCB5b3Vyc2VsZixnbyBkaWUsZnVjayB5b3UsZnVjayBvZmYsc2NyZXcgeW91LGdvIHRvIGhlbGwsZGllIGJpdGNoLHBpZWNlIG9mIHNoaXQsa3lzLGkgaGF0ZSB5b3U="
        guard let data = Data(base64Encoded: encoded),
              let decoded = String(data: data, encoding: .utf8) else { return [] }
        return decoded.components(separatedBy: ",")
    }()
}
