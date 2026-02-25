# Learn FM Project Plan

## Project Overview

- **Project Name:** Learn FM
- **Project Owner:** Ashwin Chuck
- **Stakeholder:** Jack Miller
- **Go-Live Date:** Today (Aggressive Timeline)
- **Tech Stack:** Flutter + Supabase + Claude AI

## Team Assignments

| Role | Agent | Responsibility |
|------|-------|----------------|
| Stakeholder/Oversight | Jack Miller | Final approvals |
| CI/CD & Deployment | architect | Pipeline setup & deployment |
| Testing & Bug Fixes | code | Unit, integration testing |
| Security Testing | security | Vulnerability assessment |
| UAT Coordination | product | User acceptance testing |

## Sprint Plan (1-Day Aggressive Timeline)

### Sprint 1 - Morning (Hours 1-3): Setup & CI/CD

- [ ] architect sets up CI/CD pipeline (GitHub Actions / Fastlane)
- [ ] Configure Supabase production environment
- [ ] Set environment variables & API keys
- [ ] Deploy backend schema to production Supabase

### Sprint 2 - Midday (Hours 4-6): Testing

- [ ] code runs unit tests on all providers
- [ ] code runs integration tests on auth & exam flows
- [ ] security performs vulnerability scan
- [ ] security reviews API key exposure & auth tokens

### Sprint 3 - Afternoon (Hours 7-9): UAT

- [ ] product coordinates UAT with FM professionals
- [ ] Test all 8 screens end-to-end
- [ ] Validate AI chat responses
- [ ] Validate exam scoring system

### Sprint 4 - Evening (Hours 10-12): Go-Live

- [ ] Fix critical bugs identified in UAT
- [ ] Final deployment to production
- [ ] Smoke test on production environment
- [ ] Go-live sign-off by Jack Miller & Ashwin Chuck

## Risk Register

| Risk | Severity | Mitigation |
|------|----------|------------|
| Same-day go-live | High | Fast-track testing, accept minor bugs |
| No QA agent assigned | Medium | code agent covers testing |
| UAT with real users same day | High | Internal UAT only today |

## Deployment Checklist

- [ ] Supabase production project created
- [ ] Claude API key configured
- [ ] Flutter build (Android/iOS) generated
- [ ] CI/CD pipeline active
- [ ] Monitoring & alerts configured

## User Stories

1. As a student, I can log in via Google OAuth or OTP
2. As a student, I can browse FM content by topic
3. As a student, I can chat with AI tutor for explanations
4. As a student, I can take timed exams and see results
5. As a student, I can track my progress on the dashboard
6. As a student, I can join community discussions
7. As an admin, I can manage content and users via Supabase
