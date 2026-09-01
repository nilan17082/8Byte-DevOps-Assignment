# Challenges & Resolutions

During the development and deployment of this DevOps pipeline and infrastructure, several key technical challenges were encountered and resolved:

### 1. Git Push Failure Due to Large Binary Blobs
* **Challenge:** Pushing the initial repository failed because the local `.terraform/providers/.../terraform-provider-aws.exe` binary (862 MB) was accidentally cached and tracked by Git, exceeding GitHub's 100 MB file size limit.
* **Resolution:** Removed local hidden `.terraform` directories, cleared the local Git history cache (`git reset origin/main` / reinitializing the local repository), reinforced the root `.gitignore` to strictly exclude local provider binaries, and pushed a clean history.

### 2. Jenkins Pipeline Groovy Syntax & Plugin Compatibility
* **Challenge:** Early iterations of the `Jenkinsfile` threw `MultipleCompilationErrorsException` due to dollar-sign interpolation clashes with complex AWS CLI query filters (`--query "repositories[0]..."`), and missing native Docker pipeline plugins on a lightweight server setup.
* **Resolution:** Refactored the `Jenkinsfile` from declarative wrapper steps to robust, standard shell (`sh`) commands using single quotes to isolate Groovy string evaluation, ensuring native execution without requiring specialized plugin wrappers.

### 3. Unit Test Database Dependencies in CI
* **Challenge:** The `npm test` script executed via Jest failed in the CI pipeline because it attempted to establish a live connection to a PostgreSQL database via `pool.query` when no live database container was present during the testing stage.


* **Resolution:** Implemented a mock for the `pg` module in `app.test.js` using Jest (`jest.mock('pg')`), allowing the test suite to validate API routing logic and endpoint responses (`/health` and `/api/data`) cleanly in isolation during CI.