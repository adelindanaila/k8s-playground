import { useCounter, useIncrementCounter, useResetCounter } from './hooks/useCounter'
import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import './App.css'

function App() {
  const { data: counter, isLoading, error } = useCounter();
  const incrementMutation = useIncrementCounter();
  const resetMutation = useResetCounter();

  const handleIncrement = () => {
    incrementMutation.mutate();
  };

  const handleReset = () => {
    resetMutation.mutate();
  };

  return (
    <>
      <div>
        <a href="https://vite.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>Vite + React</h1>
      <div className="card">
        {isLoading && <p>Loading counter...</p>}
        {error && <p style={{ color: 'red' }}>Error: {error.message}</p>}
        {counter && (
          <>
            <button 
              onClick={handleIncrement}
              disabled={incrementMutation.isPending}
            >
              count is {counter.value}
            </button>
            <button 
              onClick={handleReset}
              disabled={resetMutation.isPending}
              style={{ marginLeft: '10px' }}
            >
              Reset
            </button>
          </>
        )}
        <p>
          Edit <code>src/App.tsx</code> and save to test HMR
        </p>
      </div>
      <p className="read-the-docs">
        Click on the Vite and React logos to learn more
      </p>
    </>
  )
}

export default App
