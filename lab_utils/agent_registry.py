"""Agent registry in-memory — mô phỏng khái niệm registry MCP server Ngày 26."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any

import httpx


@dataclass
class RegisteredAgent:
    name: str
    url: str
    description: str
    capabilities: dict[str, Any] = field(default_factory=dict)
    healthy: bool = True
    registered_at: str = field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )


class AgentRegistry:
    def __init__(self) -> None:
        self._agents: dict[str, RegisteredAgent] = {}

    def register(self, agent: RegisteredAgent) -> None:
        self._agents[agent.name] = agent

    def deregister(self, name: str) -> None:
        self._agents.pop(name, None)

    def set_health(self, name: str, healthy: bool) -> None:
        if name in self._agents:
            self._agents[name].healthy = healthy

    def list_agents(self, healthy_only: bool = False) -> list[RegisteredAgent]:
        agents = list(self._agents.values())
        if healthy_only:
            agents = [agent for agent in agents if agent.healthy]
        return agents

    def health_check(self, name: str, timeout: float = 5.0) -> bool:
        agent = self._agents.get(name)
        if agent is None:
            return False

        card_url = agent.url.rstrip("/") + "/.well-known/agent-card.json"
        candidate_urls = [card_url]
        if "localhost" in card_url:
            candidate_urls.append(card_url.replace("localhost", "127.0.0.1"))

        healthy = False
        for url in candidate_urls:
            try:
                response = httpx.get(url, timeout=timeout)
                if response.status_code == 200:
                    healthy = True
                    break
            except httpx.HTTPError:
                continue

        agent.healthy = healthy
        return healthy

    def health_check_all(self, timeout: float = 5.0) -> dict[str, bool]:
        return {
            name: self.health_check(name, timeout=timeout)
            for name in list(self._agents)
        }

    def find_by_capability(self, keyword: str) -> list[RegisteredAgent]:
        keyword_lower = keyword.lower()
        return [
            agent
            for agent in self._agents.values()
            if keyword_lower in agent.description.lower()
            or keyword_lower in str(agent.capabilities).lower()
        ]
