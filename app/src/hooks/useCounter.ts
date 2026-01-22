import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient, type Counter } from '../lib/api';

const COUNTER_QUERY_KEY = ['counter'] as const;

export function useCounter() {
  return useQuery<Counter, Error>({
    queryKey: COUNTER_QUERY_KEY,
    queryFn: async () => {
      const { data, error, response } = await apiClient.GET('/api/counter');
      if (error) {
        throw new Error(`Failed to fetch counter: ${response.statusText}`);
      }
      return data!;
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
      const { data, error, response } = await apiClient.POST('/api/counter/increment');
      if (error) {
        throw new Error(`Failed to increment counter: ${response.statusText}`);
      }
      return data!;
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
      const { data, error, response } = await apiClient.POST('/api/counter/reset');
      if (error) {
        throw new Error(`Failed to reset counter: ${response.statusText}`);
      }
      return data!;
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
      const { data, error, response } = await apiClient.PUT('/api/counter', {
        body: { value },
      });
      if (error) {
        throw new Error(`Failed to set counter: ${response.statusText}`);
      }
      return data!;
    },
    onSuccess: (data) => {
      queryClient.setQueryData<Counter>(COUNTER_QUERY_KEY, data);
      queryClient.invalidateQueries({ queryKey: COUNTER_QUERY_KEY });
    },
  });
}
