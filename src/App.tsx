import { Component, type ReactNode } from 'react';
import AppShell from './components/AppShell';

interface ErrorBoundaryState {
  hasError: boolean;
  error: string;
}

class ErrorBoundary extends Component<{ children: ReactNode }, ErrorBoundaryState> {
  state: ErrorBoundaryState = { hasError: false, error: '' };

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error: `${error.name}: ${error.message}` };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    const entry = `[${new Date().toISOString()}] REACT CRASH: ${error.name}: ${error.message}\nStack: ${error.stack}\nComponent: ${info.componentStack}`;
    console.error('[MarkScout]', entry);
    try {
      const key = 'markscout-diagnostic-log';
      const prev = localStorage.getItem(key) || '';
      const lines = prev.split('\n').filter(Boolean).slice(-89);
      lines.push(entry);
      localStorage.setItem(key, lines.join('\n'));
    } catch { /* ignore */ }
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
          height: '100vh', background: '#0d0d0d', color: '#e0e0e0', fontFamily: 'system-ui',
          padding: 40, textAlign: 'center',
        }}>
          <h1 style={{ fontSize: 20, marginBottom: 12, color: '#d4a04a' }}>MarkScout crashed</h1>
          <p style={{ fontSize: 13, color: '#888', marginBottom: 20, maxWidth: 500 }}>
            {this.state.error}
          </p>
          <button
            onClick={() => { this.setState({ hasError: false, error: '' }); }}
            style={{
              padding: '8px 20px', background: '#1e1e1e', border: '1px solid #2a2a2a',
              color: '#e0e0e0', borderRadius: 6, cursor: 'pointer', fontSize: 13,
            }}
          >
            Try again
          </button>
          <p style={{ fontSize: 11, color: '#555', marginTop: 16 }}>
            Diagnostic log saved to localStorage key: markscout-diagnostic-log
          </p>
        </div>
      );
    }
    return this.props.children;
  }
}

export default function App() {
  return (
    <ErrorBoundary>
      <AppShell />
    </ErrorBoundary>
  );
}
