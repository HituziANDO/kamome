export function undefinedToNull<T>(value: T | undefined): T | null {
    return value === undefined ? null : value;
}
