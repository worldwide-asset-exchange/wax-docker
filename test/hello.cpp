// Minimal but real contract fixture: exercises the full CDT toolchain —
// clang-9 (needs libz3), wasm-ld (needs libxml2), and the ABI generator.
// The class name must match the -o basename that cdt-cpp is given.
#include <eosio/eosio.hpp>

using namespace eosio;

class [[eosio::contract]] hello : public contract {
  public:
    using contract::contract;

    [[eosio::action]] void hi(name user) {
        require_auth(user);
        print("Hello, ", user);
    }

    [[eosio::action]] void check(uint64_t value) {
        eosio::check(value > 0, "value must be positive");
    }
};
