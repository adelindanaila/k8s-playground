import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient, type Counter } from '../lib/api';

const COUNTER_QUERY_KEY = ['counter'] as const;

// Helper to handle openapi-fetch result
function handleApiResult<T>(result: { data?: T; error?: unknown; response?: Response }) {
  if (result.error !== undefined) {
    throw new Error(`API error: ${String(result.error)}`);
  }
  if (!result.data) {
    throw new Error('No data returned from API');
  }
  return result.data;
}

export function useCounter() {
  return useQuery<Counter, Error>({
    queryKey: COUNTER_QUERY_KEY,
    queryFn: async () => {
      const result = await apiClient.GET('/api/counter');
      return handleApiResult(result);
    },
    staleTime: 1000,
    retry: 2,
    retryDelay: 1000,
  });
}

export function useIncrementCounter() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async () => {
      const result = await apiClient.POST('/api/counter/increment');
      return handleApiResult(result);
    },
    onSuccess: (data) => {
      queryClient.setQueryData<Counter>(COUNTER_QUERY_KEY, data);
      queryClient.invalidateQueries({ queryKey: COUNTER_QUERY_KEY });
    },
  });
}

export function useResetCounter() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async () => {
      const result = await apiClient.POST('/api/counter/reset');
      return handleApiResult(result);
    },
    onSuccess: (data) => {
      queryClient.setQueryData<Counter>(COUNTER_QUERY_KEY, data);
      queryClient.invalidateQueries({ queryKey: COUNTER_QUERY_KEY });
    },
  });
}

export function useSetCounter() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (value: number) => {
      const result = await apiClient.PUT('/api/counter', {
        body: { value },
      });
      return handleApiResult(result);
    },
    onSuccess: (data) => {
      queryClient.setQueryData<Counter>(COUNTER_QUERY_KEY, data);
      queryClient.invalidateQueries({ queryKey: COUNTER_QUERY_KEY });
    },
  });
}
