all:
	## Create the object file for AES encryption
	gcc -g -I. -Icrypto/include -Iinclude -fPIC -pthread -m64 -Wa,--noexecstack -DDEBUG_UNUSED -DPEDANTIC -pedantic -Wno-long-long -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Wswitch -Wsign-compare -Wmissing-prototypes -Wstrict-prototypes -Wshadow -Wformat -Wtype-limits -Wundef -Werror -Wall -O2 -g -DOPENSSL_USE_NODELETE -DL_ENDIAN -DOPENSSL_PIC -DOPENSSL_CPUID_OBJ -DOPENSSL_IA32_SSE2 -DOPENSSL_BN_ASM_MONT -DOPENSSL_BN_ASM_MONT5 -DOPENSSL_BN_ASM_GF2m -DSHA1_ASM -DSHA256_ASM -DSHA512_ASM -DKECCAK1600_ASM -DRC4_ASM -DMD5_ASM -DVPAES_ASM -DBSAES_ASM -DGHASH_ASM -DECP_NISTZ256_ASM -DX25519_ASM -DPADLOCK_ASM -DPOLY1305_ASM -DOPENSSLDIR="/usr/local/ssl" -DENGINESDIR="/usr/local/lib/engines-1.1" -MMD -MF aes_core.d.tmp -MT aes_core.o -c -o aes_core.o aes_core.c
	## Generate the benchmark with the key protected
	gcc -Wall -g -DWB_ON_RETIRE -static -O2 -Iinclude -o specBench_wbor specBench.c aes_core.o
	## and relink it so the .non-speculative section is protected
	./gen_link_script.pl specBench_wbor specBench_wbor.lds
	gcc -Wall -g -DWB_ON_RETIRE -static -O2 -Iinclude -T specBench_wbor.lds -o specBench_wbor specBench.c aes_core.o
	## Generate the benchmark without the key protected
	gcc -Wall -g -static -O2 -Iinclude -o specBench_base specBench.c aes_core.o
	./gen_link_script.pl specBench_base specBench_base.lds
	gcc -Wall -g -static -O2 -Iinclude -T specBench_base.lds -o specBench_base specBench.c aes_core.o
	## generate the test to check that different memory areas are being marked correctly
	gcc -Wall -g -static -O2 -o markTest markTest.c
	./gen_link_script.pl markTest markTest.lds
	gcc -Wall -g -static -O2 -T markTest.lds -o markTest markTest.c
	## generate the test to check that Spectre is being mitigated
	gcc -Wall -g -static -o spectre_attack spectre_attack.c
	./gen_link_script.pl spectre_attack spectre_attack_mit.lds
	gcc -Wall -g -static -T spectre_attack_mit.lds -o spectre_attack_mit spectre_attack.c

clean:
	rm -rf specBench_base specBench_base.lds specBench_wbor specBench_wbor.lds
	rm -rf markTest markTest.lds
	rm -rf spectre_attack spectre_attack_mit spectre_attack_mit.lds
	rm -rf aes_core.o aes_core.d.tmp
