package main

import (
	"strconv"
	"strings"
)

func cpuMilli(raw string) (int, bool) {
	s := strings.TrimSpace(raw)
	if s == "" {
		return 0, false
	}
	if strings.HasSuffix(s, "m") {
		n, err := strconv.ParseFloat(strings.TrimSuffix(s, "m"), 64)
		if err != nil {
			return 0, false
		}
		return int(n + 0.5), true
	}
	n, err := strconv.ParseFloat(s, 64)
	if err != nil {
		return 0, false
	}
	return int(n*1000 + 0.5), true
}

func memBytes(raw string) (int64, bool) {
	s := strings.TrimSpace(raw)
	if s == "" {
		return 0, false
	}
	mult := int64(1)
	for _, suffix := range []struct {
		text string
		mult int64
	}{
		{"Ki", 1024},
		{"Mi", 1024 * 1024},
		{"Gi", 1024 * 1024 * 1024},
		{"K", 1000},
		{"M", 1000 * 1000},
		{"G", 1000 * 1000 * 1000},
	} {
		if strings.HasSuffix(s, suffix.text) {
			s = strings.TrimSuffix(s, suffix.text)
			mult = suffix.mult
			break
		}
	}
	n, err := strconv.ParseFloat(s, 64)
	if err != nil {
		return 0, false
	}
	return int64(n * float64(mult)), true
}

func cpuEqual(got, want string) bool {
	a, aok := cpuMilli(got)
	b, bok := cpuMilli(want)
	return aok && bok && a == b
}

func memEqual(got, want string) bool {
	a, aok := memBytes(got)
	b, bok := memBytes(want)
	return aok && bok && a == b
}

func resourcesOK(c M, reqCPU, reqMem, limCPU, limMem string) bool {
	return c != nil &&
		cpuEqual(text(c, "resources", "requests", "cpu"), reqCPU) &&
		memEqual(text(c, "resources", "requests", "memory"), reqMem) &&
		cpuEqual(text(c, "resources", "limits", "cpu"), limCPU) &&
		memEqual(text(c, "resources", "limits", "memory"), limMem)
}

func rolloutComplete(o M, replicas int) bool {
	return integer(o, "spec", "replicas") == replicas &&
		integer(o, "status", "updatedReplicas") == replicas &&
		integer(o, "status", "availableReplicas") == replicas &&
		integer(o, "metadata", "generation") == integer(o, "status", "observedGeneration")
}
