#include <stdio.h>
#include <stdint.h>

void     *vec_init(void);
void 	  vec_free(void *);
void 	  vec_push(void *, uintptr_t);
uintptr_t vec_at  (void *, size_t);

int main()
{
	void *vec = vec_init();
	if (!vec) {
		printf("failed to allocate vec\n");
		return 1;
	}

	size_t i;
	for (i = 0; i < 10; ++i)
		vec_push(vec, i);
	for (i = 0; i < 10; ++i)
		printf("%d\n", vec_at(vec, i));
	vec_free(vec);
	return 0;
}

