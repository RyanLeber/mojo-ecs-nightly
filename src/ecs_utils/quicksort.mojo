

fn partition_lt[type: DType, size: Int](inout arr: SIMD[type, size], low: Int, high: Int) -> Int:
    pivot = arr[high]
    i = low - 1
    
    for j in range(low, high):
        if arr[j] < pivot:
            i += 1
            swap(arr[i], arr[j])
    
    swap(arr[i + 1], arr[high])
    return i + 1


fn partition_gt[type: DType, size: Int](inout arr: SIMD[type, size], low: Int, high: Int) -> Int:
    pivot = arr[high]
    i = low - 1
    
    for j in range(low, high):
        if arr[j] > pivot:
            i += 1
            swap(arr[i], arr[j])
    
    swap(arr[i + 1], arr[high])
    return i + 1


fn quick_sort[type: DType, size: Int, //, reverse: Bool= False](inout arr: SIMD[type, size], low: Int = 0, high: Int = size - 1):
    if low < high:
        var pi: Int
        @parameter
        if reverse:
            pi = partition_gt(arr, low, high)
        else:
            pi = partition_lt(arr, low, high)


        quick_sort[reverse](arr, low, pi - 1)
        quick_sort[reverse](arr, pi + 1, high)
