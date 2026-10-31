import './App.css';

const STEPS = [

  {

    icon: '📝',

    color: '#6366f1',

    title: 'Developer Commits Code',

    desc: 'Any code change is committed locally and pushed to GitHub. The branch you push to determines what happens next in the pipeline.',

    tag: 'git commit & git push',

  },

  {

    icon: '⚙️',

    color: '#06b6d4',

    title: 'GitHub Actions Triggers',

    desc: 'GitHub detects the push and automatically triggers the matching workflow file in .github/workflows/. No manual action needed — it runs on its own.',

    tag: '.github/workflows/',

  },

  {

    icon: '🧪',

    color: '#8b5cf6',

    title: 'Tests & Lint Run',

    desc: (
<>

        The CI job installs dependencies with <code>npm ci</code>, runs ESLint to catch code issues, then runs all test cases with <code>npm test</code>. If any test fails, the pipeline stops here and the team is notified.
</>

    ),

    tag: 'runs on every branch push',

  },

  {

    icon: '🐳',

    color: '#f59e0b',

    title: 'Docker Image is Built',

    desc: (
<>

        When tests pass on <code>dev</code> or <code>main</code>, GitHub Actions builds a Docker image using the <code>Dockerfile</code>. It uses a multi-stage build — Node.js compiles the React app, then Nginx serves it.
</>

    ),

    tag: 'dev branch & main branch',

  },

  {

    icon: '📦',

    color: '#10b981',

    title: 'Image Pushed to Docker Hub',

    desc: (
<>

        The built image is pushed to Docker Hub. On <code>dev</code> it is tagged <code>dev-latest</code>. On <code>main</code> it is tagged <code>latest</code> — the production-ready image.
</>

    ),

    tag: 'dev → dev-latest  |  main → latest',

  },

  {

    icon: '☁️',

    color: '#0ea5e9',

    title: 'Deployed to Azure Linux VM',

    desc: (
<>

        Only when code is merged to <code>main</code> does GitHub Actions SSH into the Azure Linux VM, pull the <code>latest</code> image, and restart the container. The <code>dev</code> branch never touches the server.
</>

    ),

    tag: 'main branch only',

  },

];

const TRIGGERS = [

  {

    color: '#06b6d4',

    branch: 'feature/* — any branch',

    steps: ['Install dependencies', 'Run ESLint', 'Run npm test', 'Build smoke test'],

  },

  {

    color: '#f59e0b',

    branch: 'dev branch → cd.yml',

    steps: ['Run tests', 'Docker image build', 'Push to Docker Hub (dev-latest)', '🚫 deploy job skipped via if condition'],

  },

  {

    color: '#10b981',

    branch: 'main branch → cd.yml',

    steps: ['Run tests', 'Docker image build', 'Push to Docker Hub (latest)', '🚀 Deploy to Azure VM runs'],

  },

];

const FILES = [

  { indent: 0, type: 'folder', name: 'reactapp/' },

  { indent: 1, type: 'folder', name: '.github/workflows/' },

  { indent: 2, type: 'new',    name: 'ci.yml',   note: '← tests on every branch push' },

  { indent: 2, type: 'new',    name: 'cd.yml',   note: '← build + push (dev) or build + push + deploy (main)' },

  { indent: 1, type: 'new',    name: 'Dockerfile',   note: '← defines how to containerise the app' },

  { indent: 1, type: 'new',    name: 'nginx.conf',   note: '← configures the web server inside Docker' },

  { indent: 1, type: 'new',    name: '.dockerignore', note: '← keeps the image lean' },

  { indent: 1, type: 'plain',  name: 'src/' },

  { indent: 1, type: 'plain',  name: 'package.json' },

];

function Step({ step, index, total }) {

  return (
<div className="step" style={{ '--color': step.color }}>
<div className="step-left">
<div className="step-icon">{step.icon}</div>

        {index < total - 1 && <div className="step-line" />}
</div>
<div className="step-body">
<div className="step-title">{step.title}</div>
<div className="step-desc">{step.desc}</div>
<span className="step-tag">{step.tag}</span>
</div>
</div>

  );

}

function App() {

  return (
<div className="app">

      {/* Header */}
<header className="header">
<div className="header-badge">⚙️ DevOps Workflow</div>
<h1>How this project's<br /><span>CI/CD Pipeline</span> works</h1>
<p>

          Every code change flows through an automated pipeline — from your local machine to a live Azure server — without any manual steps.
</p>
</header>

      {/* Workflow Steps */}
<div className="section-label">The Pipeline — Step by Step</div>
<div className="workflow">

        {STEPS.map((step, i) => (
<Step key={i} step={step} index={i} total={STEPS.length} />

        ))}
</div>

      {/* Branch Triggers */}
<div className="triggers">
<div className="section-label">What Triggers What</div>
<div className="trigger-grid">

          {TRIGGERS.map(t => (
<div className="trigger-card" key={t.branch} style={{ '--color': t.color }}>
<div className="trigger-branch">🌿 {t.branch}</div>
<ul className="trigger-steps">

                {t.steps.map(s => <li key={s}>{s}</li>)}
</ul>
</div>

          ))}
</div>
</div>

      {/* Files Added */}
<div className="file-tree-section">
<div className="section-label">Files Added to This Project</div>
<div className="file-tree">

          {FILES.map((f, i) => (
<div key={i} style={{ paddingLeft: `${f.indent * 20}px` }}>
<span className={f.type === 'folder' ? 'folder' : f.type === 'new' ? 'file-new' : ''}>

                {f.type === 'folder' ? '📁 ' : f.type === 'new' ? '✦ ' : '  '}{f.name}
</span>

              {f.note && <span className="file-note">{f.note}</span>}
</div>

          ))}
</div>
</div>
<footer className="footer">

        React · GitHub Actions · Docker Hub · Azure Linux VM
</footer>
</div>

  );

}

export default App;
 